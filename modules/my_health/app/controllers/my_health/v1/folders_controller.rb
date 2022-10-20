# frozen_string_literal: true

module MyHealth
  module V1
    class FoldersController < SMController
      def index
        resource = client.get_folders(1, use_cache? || true)
        resource = resource.paginate(pagination_params)

        render json: resource.data,
               serializer: CollectionSerializer,
               each_serializer: MyHealth::V1::FolderSerializer,
               meta: resource.metadata
      end

      def show
        id = params[:id].try(:to_i)
        resource = client.get_folder(id)
        raise Common::Exceptions::RecordNotFound, id if resource.blank?

        render json: resource,
               serializer: MyHealth::V1::FolderSerializer,
               meta: resource.metadata
      end

      def create
        folder = Folder.new(create_folder_params)
        raise Common::Exceptions::ValidationErrors, folder unless folder.valid?

        resource = client.post_create_folder(folder.name)

        render json: resource,
               serializer: MyHealth::V1::FolderSerializer,
               meta: resource.metadata,
               status: :created
      end

      def destroy
        client.delete_folder(params[:id])
        head :no_content
      end

      def search
        messageSearch = MessageSearch.new(search_params)
        resource = client.search_folder(params[:id], params[:page], params[:per_page], messageSearch)

        render json: resource.data,
               serializer: CollectionSerializer,
               each_serializer: MessagesSerializer,
               meta: resource.metadata
      end

      private

      def create_folder_params
        params.require(:folder).permit(:name)
      end

      def search_params
        params.permit(:exact_match, :sender, :subject, :category, :recipient, :from_date,:to_date, :message_id)
      end
    end
  end
end
