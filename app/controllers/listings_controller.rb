class ListingsController < ApplicationController
  # GET /listingssession
  # GET /listings.json
  before_filter :require_login
  def index
    @user = User.find(session[:user_id])
    puts @user.inspect
    @listings = @user.listings.all(:order => 'created_at DESC')
    puts @listings
    #@listings = Listing.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json => @listings }
    end
  end

  # GET /listings/1
  # GET /listings/1.json
  def show
    @ajxRqst = false
    if(!request.xhr?)
      @ajxRqst = true
    end
    @listing = Listing.find(params[:id])
    puts @listing.inspect
    @pictures = @listing.pictures

    render :html => "show", :layout => @ajxRqst

#    respond_to do |format|
#      #format.html { :layout => false }# show.html.erb
#
#      format.json { render json: @listing }
#    end
  end

  # GET /listings/new
  # GET /listings/new.json
  def new
    @listing = Listing.new

    respond_to do |format|
      format.html  # new.html.erb
      format.json { render json => @listing }
    end
  end

  # GET /listings/1/edit
  def edit
    @listing = Listing.find(params[:id])
  end

  # POST /listings
  # POST /listings.json
  def create
    puts params[:listing]
    params[:listing][:tap_description] = params[:listing][:description].to_s + "-"+params[:listing][:bedrooms].to_s + "Beds-"+ params[:listing][:bathrooms].to_s + "Baths -" + params[:listing][:squarefootage].to_s + "sq.ft"
    @listing = Listing.new(params[:listing])
    @listing.user_id = current_user.id
    if !params[:image_file].nil?
      @uploadimages = Picture.new
      @uploadimages.upload_file_name = params[:image_file].original_filename
      @uploadimages.upload_content_type = params[:image_file].content_type
      @uploadimages.upload_file_size = params[:image_file].size
      @uploadimages.data = params[:image_file].read
    end
    respond_to do |format|
      if @listing.save
        @listings = Listing.where(:user_id => current_user.id)
        if !params[:image_file].nil?
          @uploadimages.listing_id = @listing.id
          @uploadimages.save
        end
        format.html { redirect_to '/mylistings', notice: 'Listing was successfully created.' }
        format.json { render json: @listings, status: :created, location: @listing }
      else
        format.html { render action: "new" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /listings/1
  # PUT /listings/1.json
  def update
    @listing = Listing.find(params[:id])
    puts "lat long"
    puts @listing.lat
    puts @listing.long

    respond_to do |format|
      if @listing.update_attributes(params[:listing])
        format.html { redirect_to '/mylistings', notice: 'Listing was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listings/1
  # DELETE /listings/1.json
  def destroy
    @listing = Listing.find(params[:id])
    @listing.destroy

    respond_to do |format|
      format.html { redirect_to listings_url }
      format.json { head :no_content }
    end
  end


  def home_search
    puts params.inspect
    @listings = Listing.where(:listing_type => params[:buy_rent])
    puts "*********************"
    puts @listings.inspect
    @listings = @listings.where("price <= ?",params[:amount].to_i) if params[:amount].present?
    puts "****************23*****"
    puts @listings.inspect
  end

  def my_search_listing
    @key_search_listings = Listing.search(params[:key_search]) if params[:key_search].present?
    query = []
    query << "listing_type = '#{params[:buy_rent]}'" if params[:buy_rent].present?
    query << "price >= #{params[:min_amount]}" if params[:min_amount].present?
    query << "price <= #{params[:max_amount]}" if params[:max_amount].present?
    query << "bedrooms = #{params[:bedrooms]}" if params[:bedrooms].present?
    query << "bathrooms = #{params[:bathrooms]}" if params[:bathrooms].present?
    query << "zipcode = #{params[:zip]}" if params[:zip].present?
    if params[:days_before] == "active" 
      query << "status = true"
    else
      query << "created_at >= '#{params[:days_before].to_i.days.ago}'"
    end

    @listings = Listing.where(query.join(" AND "))
    render :layout => false
  end


  def get_contact
    @user = Listing.find(params[:listing_id].to_i).user

    @ud =   UserDetail.find_by_uid(@user.uid)

    render :html => "get_contact", :layout => false
  end

  def show_image
      @image = Picture.find(params[:id])
      send_data @image.data, :type => 'image/png', :disposition => 'inline'
  end

  def add_images

      @pictures = Listing.where(:id => params[:listing_id]).first.pictures
     render :html => "add_images", :layout => false
  end

  def upload_image
    uploadimages = Picture.new
    uploadimages.upload_file_name = params[:image_file].original_filename
    uploadimages.upload_content_type = params[:image_file].content_type
    uploadimages.upload_file_size = params[:image_file].size
    uploadimages.data = params[:image_file].read
    uploadimages.listing_id = params[:listing_id]
    uploadimages.save!
    render :text => uploadimages.id
    #puts "saved"
  end

  def rename
    @listing = Listing.find(params[:id])
    @listing.update_attribute('name', params["listing-name"])
    redirect_to mylistings_path
  end
end
