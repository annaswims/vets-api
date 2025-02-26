The Notice of Disagreements API lets internal VA teams create and manage board appeals (known as Notice of Disagreements (NODs)). NODs can be requested after an initial claim, Supplemental Claim, or Higher-Level Review decision is made. [Learn more about Notice of Disagreements](https://www.va.gov/decision-reviews/board-appeal/).  

To check the status of all decision reviews and appeals for a specified individual, use the [Appeals Status API](https://developer.va.gov/explore/appeals/docs/appeals?version=current).

## Technical overview
The Notice of Disagreements API pulls data from Caseflow, a case management system. It provides decision review and appeal data that can be used for submitting a Notice of Disagreement.

### Authorization and Access
To gain access to this API you must [request an API Key](https://developer.va.gov/apply). API requests are authorized through a symmetric API token which is provided in an HTTP header named `apikey`.

Because this application is designed to let third-parties request information on behalf of a claimant, we are not using VA Authentication Federation Infrastructure (VAAFI) headers or Single Sign On External (SSOe).

### Submission statuses
Use the correct GET endpoint to check the status of a Notice of Disagreement submission. 

These endpoints return the status of the submission in Caseflow but not the status of the submission in VBMS, which is the status visible to claimants. Therefore, VBMS statuses are different from the statuses this API returns. 

To check the status of an appeal as it will appear to a claimant, use the Appeals Status API.

| Status      | What it means |
| ---        |     ---     |
| pending      | Submission successfully received by the API but has not yet started processing. |
| submitting   | Data is transferring to upstream systems but is not yet complete. |
| submitted   | A submitted status means the data was successfully transferred to the central mail portal.<br /><br />A submitted status is confirmation from the central mail portal that they have received the PDF, but the data is not yet being processed. The Date of Receipt is set when this status is achieved.<br /><br />Submitted is the final status in the sandbox environment.<p> |
| processing   | Indicates intake has begun, the Intake, Conversion and Mail Handling Services (ICMHS) group is processing the appeal data. |
| success   | The centralized mail portal, Digital Mail Handling System (DHMS), has received the data. |
| complete   | Final status. Indicates the document package has been successfully associated with the Veteran and has been received in the correct business area for processing. Claim is now established in VBMS.|
| error   | An error occurred. See the error code and message for further information. |

### Status simulation in sandbox and staging
Test submissions do not progress through the same statuses as the production environment. In sandbox and staging, the final status of a submission is `submitted`; however, we allow passing a `Status-Simulation` header on the show endpoints so that you can simulate all production statuses. 

Statuses can also be simulated for evidence document uploads.

### Evidence uploads
Our NOD evidence submission endpoints allow a client to upload a document package (documents and metadata) of supporting evidence for their submission by following these steps.
1. Use the `POST /evidence_submissions` to return a JSON service response with the attributes listed below.
    * `guid`: An identifier used for subsequent evidence upload status requests (not to be confused with the NOD submission GUID)
    * `location`: A URL to which the actual document package payload can be submitted in the next step. The URL is specific to this upload request, and should not be re-used for subsequent uploads. The URL is valid for 900 seconds (15 minutes) from the time of this response. If the location is not used within 15 minutes, the GUID will expire. Once expired, status checks on the GUID will return a status of `expired`.
2. Client Request: PUT to the location URL returned in step 1.
    * Request body should be encoded as binary multipart/form-data, equivalent to that generated by an HTML form submission or using "curl -F...".
    * No `apikey` authorization header is required for this request, as authorization is embedded in the signed location URL.
    * The metadata.json file uploaded to the location URL with the evidence documents MUST contain all required information. See example below. -The JSON key for the metadata.json file is "metadata", the initial file is "content". Any subsequent file will be "attachment1", "attachment2", and so forth.
3. The service response will include:
    * HTTP status to indicate whether the evidence document upload was successful.
    * ETag header containing an MD5 hash of the submitted payload. This can be compared to the submitted payload to ensure data integrity of the upload.

Example m`etadata.json` file:
```
{
    "veteranFirstName": "Jane",
    "veteranLastName": "Doe",
    "fileNumber": "012345678",
    "zipCode": "94402",
    "source": "Vets.gov",
    "docType": "316"
}
```

The API will set the businessLine for your Evidence submission to ensure the documents are routed to the correct group within VA. You may check the status of your evidence document upload by using `GET /evidence_submissions/{uuid}`. If, after you've uploaded a document, the status hasn't changed to `uploaded` before 15 minutes has elapsed, we recommend retrying the submission to make sure the document properly reaches our servers.

For NODs, evidence may only be uploaded within 90 days of the NOD reaching submitted status. After 90 days an error will be returned if evidence uploads related to this NOD are attempted. 

#### Evidence upload statuses
The evidence document upload statuses begin with pending and end with vbms.

Note that until a document status of "received", "processing", "success", or "vbms" is returned, a client cannot consider the document as received by VA. In particular a status of "uploaded" means that the document package has been transmitted, but possibly not validated. Any errors with the document package (unreadable PDF, etc) may cause the status to change to "error".

The metadata.json file only supports a limited set of characters within the ascii character space. Refer to the `documentUploadMetadata` schema for more details.

| Status      | What it means |
| ---        |     ---     |
| pending      | Initial status of the submission when no supporting documents have been uploaded. |
| uploaded   | Indicates document package has been successfully uploaded (PUT) from the vendor's application system to the API server but has not yet been validated. Date of Receipt is not yet established with this status. |
| received   | Indicates document package has been received upstream of the API, but is not yet in processing. Date of Receipt is set when this status is achieved. (This is also the final status in the sandbox environment unless further progress is simulated.) |
| processing   | Indicates intake has begun, the Intake, Conversion and Mail Handling Services (ICMHS) group is processing the appeal data. |
| success   | The centralized mail portal, Digital Mail Handling System (DHMS), has received the data. |
| vbms   | Final status. Indicates document package has been received by Veterans Benefits Management System (VBMS). |
| error   | An error occurred. See the error code and message for further information. |

### Status Caching
Due to system limitations, status attribute data for these endpoints is cached for 1 hour: 
* GET `/forms/10182/{uuid}`
* GET `/evidence_submission/{uuid}`

The updated_at field indicates the last time the status for a given GUID was updated.

[Terms of service](https://developer.va.gov/terms-of-service)

