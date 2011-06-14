class DocumentsController < ApplicationController
  before_filter :authenticate, :except => [:login, :verify]
  
  def login
    @username = ''
    @password = ''
  end
  
  def new_file
    case params[:type]
      when 'document'
        doc = Document.new(@account)
      when 'presentation'
        doc = Presentation.new(@account)
      when 'spreadsheet'
        doc = Spreadsheet.new(@account)
    end
    doc.title = params[:title]
    if doc.save
      flash[:notice] = params[:type].capitalize+' Created!'
      redirect_to :action => :view, :doc_id => doc.id and return
    else
      flash[:warning] = "Could not create "+params[:type].capitalize+"!"
      redirect_to :action => :index and return
    end
  end
  
  def save_folder
    folder = Folder.new(@account)
    folder.title = params[:title]
    if folder.save
      flash[:notice] = 'Folder saved!'
      if params[:parent] and params[:parent] != ''
        parent = Folder.find(@account, {:id => params[:parent]})
        if parent
          folder.add_to_folder(parent)
        end
      end
    else
      flash[:warning] = 'Could not save folder!'
    end
    redirect_to :action => :index
  end
  
  def new_folder
    @folders = @account.folders
  end
  
  def update_doc_folder
    if params[:do] == 'delete'
      @document = Document.find(@account, {:id => CGI::unescape(params[:doc_id])})
      @folder = Folder.find(@account, CGI::unescape(params[:folder])).first
      @document.remove_from_folder(@folder) if @folder
    else
      @document = Document.find(@account, {:id => CGI::unescape(params[:doc_id])})
      @folder = Folder.find(@account, {:id => CGI::unescape(params[:folder])})
      @document.add_to_folder(@folder) if @folder
    end
    redirect_to :action => :view, :doc_id => @document.id
  end
  
  def index
    if not params[:folder_id]
      @documents = @account.files
      @folders = @account.folders.select{|f| !f.parent }
    else
      @folder = Folder.find(@account, {:id => params[:folder_id]})
      @documents = @folder.files
      @folders = @folder.folders
    end
  end
  
  def browse
    @folder = Folder.find(@account, {:id => CGI::unescape(params[:folder_id])})
    @documents = @folder.files
  end
  
  def edit
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
  end
  
  def edit_iframe
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
  end
  
  def view
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
  end
  
  def download
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    send_data @document.get_content(params[:type]), :disposition => 'inline', :filename => "#{@document.title}.#{params[:type]}"
  end
  
  def save
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    @document.title = params[:title]
    @document.save
    redirect_to :action => :view, :doc_id => @document.id
  end
  
  def save_content
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    @document.put_content(params[:content])
    redirect_to :action => :view, :doc_id => @document.id
  end
  
  def add_user
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    @document.add_access_rule(params[:user], params[:role])
    redirect_to :action => :view, :doc_id => @document.id
  end
  
  def update_user
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    @document.update_access_rule(params[:user], params[:role])
    redirect_to :action => :view, :doc_id => @document.id    
  end
  
  def remove_user
    @document = BaseObject.find(@account, {:id => CGI::unescape(params[:doc_id])})
    @document.remove_access_rule(params[:user])
    redirect_to :action => :view, :doc_id => @document.id
  end
  
  def send_upload
    if params[:doc_id]
      doc = BaseObject.find(@account, {:id => params[:doc_id]})
      doc.content = params[:upload_file].read
      doc.content_type = File.extname(params[:upload_file].original_filename).gsub(".", "")
      if doc.save
        flash[:notice] = 'File successfully uploaded'
      else
        flash[:warning] = 'Could not upload file!'
      end
      redirect_to :action => :view, :doc_id => doc.id and return
    else
      file = BaseObject.new(@account)
      file.title = params[:upload_file].original_filename.gsub(/\.\w.*/, "")
      file.content = params[:upload_file].read
      file.content_type = File.extname(params[:upload_file].original_filename).gsub(".", "")
      if file.save
        flash[:notice] = 'File successfully uploaded'
      else
        flash[:warning] = 'Could not upload file!'
      end
      redirect_to :action => :index and return
    end
  end
  
  def search
    if not params[:term] and not params[:args] or not params[:args][:title]
      render :action => :search and return
    else
      if params[:args][:title] == ''
        params[:args].delete(:title)
      end
      @documents = BaseObject.find(@account, params[:term], 'any', params[:args])
      render :action => :search_results and return
    end
  end
  
  def delete
    obj = nil
    if params[:doc_id]
      obj = BaseObject.find(@account, {:id => params[:doc_id]})
    elsif params[:folder_id]
      obj = Folder.find(@account, {:id => params[:folder_id]})
    end
    if obj and obj.delete
      flash[:notice] = 'Successfully deleted!'
    else
      flash[:notice] = "Error deleting!"
    end
    redirect_to request.referer
  end
  
  def verify
    @username = params[:username]
    @password = params[:password]
    if params[:username].empty? or params[:password].empty?
      flash[:warning] = 'You must enter a username and password.'
      render :action => :login and return 
    end
    begin
      service = Service.new
      service.authenticate(params[:username], params[:password])
    rescue AuthenticationFailed
      flash[:warning] = 'Username or password is incorrect!'
      render :action => :login and return
    end
    session[:username] = params[:username]
    session[:password] = params[:password]
    redirect_to :action => :index
  end
  
  def logout
    session[:username] = nil
    session[:password] = nil
    flash[:notice] = 'You have been logged out.'
    redirect_to :action => :login
  end
end
