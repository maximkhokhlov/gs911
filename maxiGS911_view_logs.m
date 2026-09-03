function varargout = maxiGS911_view_logs(varargin)
% MAXIGS911_VIEW_LOGS MATLAB code for maxiGS911_view_logs.fig
%      MAXIGS911_VIEW_LOGS, by itself, creates a new MAXIGS911_VIEW_LOGS or raises the existing
%      singleton*.
%
%      H = MAXIGS911_VIEW_LOGS returns the handle to a new MAXIGS911_VIEW_LOGS or the handle to
%      the existing singleton*.
%
%      MAXIGS911_VIEW_LOGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAXIGS911_VIEW_LOGS.M with the given input arguments.
%
%      MAXIGS911_VIEW_LOGS('Property','Value',...) creates a new MAXIGS911_VIEW_LOGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maxiGS911_view_logs_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maxiGS911_view_logs_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help maxiGS911_view_logs

% Last Modified by GUIDE v2.5 25-Sep-2013 15:15:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @maxiGS911_view_logs_OpeningFcn, ...
    'gui_OutputFcn',  @maxiGS911_view_logs_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before maxiGS911_view_logs is made visible.
function maxiGS911_view_logs_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to maxiGS911_view_logs (see VARARGIN)

% Choose default command line output for maxiGS911_view_logs
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes maxiGS911_view_logs wait for user response (see UIRESUME)
% uiwait(handles.figure1);


im=imread('feder ivanovich khokhlov - letnya polyana.JPG');
axes(handles.ax_main);
imshow(im)


% --- Outputs from this function are returned to the command line.
function varargout = maxiGS911_view_logs_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function txt_file_Callback(hObject, eventdata, handles) %#ok<DEFNU,*INUSD>
% hObject    handle to txt_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_file as text
%        str2double(get(hObject,'String')) returns contents of txt_file as a double


% --- Executes during object creation, after setting all properties.
function txt_file_CreateFcn(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to txt_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_browse.
function pb_browse_Callback(hObject, eventdata, handles) %#ok<DEFNU>
% hObject    handle to pb_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname,pname] = uigetfile({'*.txt;*.csv','Log files';'*.txt','Text files';'*.csv','CSV files';'*.*','All Files'},'Load first log file');
if fname == 0
    return
end


set(handles.txt_file,'String',[pname fname]);

try
    rawData = importdata([pname fname], ';', 6);
catch
    error(['Error occured during opening ' fname ' file']);
end

set(handles.tbl_par,'data',[rawData.colheaders;num2cell(ones(1,length(rawData.colheaders)))]');



% --- Executes on button press in pb_extractd.
function pb_extractd_Callback(hObject, eventdata, handles)
% hObject    handle to pb_extractd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


parameters=handles.selected_parameters;

if get(handles.cb_load_all_files,'value') %load all csv and txt log files
    [pathstr, name, ext]= fileparts(get(handles.txt_file,'String')) ;
    
    
    files=dir([pathstr '\*.csv']);
    files=[files; dir([pathstr '\*.txt'])];
    
    fnames=sort({files.name}');
    
    disp(['Found ' num2str(length(files)) ' files'])
    
    
    data=[];
    for m=1:length(fnames)
        
        fname=char(fnames(m));
        
        [data_buf, cols_names_buf]=extract_data([pathstr '\' fname],parameters);
        
        
        
        % if data extract was successful
        if ~isempty(data_buf) && (size(data_buf,2)== length(parameters)+1)
            
            
            
            % check date range to eliminate corrupted data
            indx= find((data_buf(:,1)>now) | (data_buf(:,1)<733408));
            
            if indx
                disp(['Date was out of range [2008->' datestr(now) '] in "' fname '"'])
                disp(['Skipping "'  fname '"'])
                continue
            end
            
            % add data
            data=[data;data_buf];
            
            % plot file by file
            if get(handles.cb_plot_by_file,'value')
                
                disp(['Plotting file :' fname])
                %plot the data
                
                
                % save data to handles
                handles.data=data_buf;
                guidata(hObject, handles);
                
                
                % plot the data
                plot_data(handles);
                
                
                pause
                
                
            end
        else
            disp(['**Skipping file :' fname])
        end
    end
    
    data=sortrows(data);
    
else %load single file
    data=extract_data(get(handles.txt_file,'String'),parameters);
end




% save data to handles
handles.data=data;
handles.parameters=parameters;
guidata(hObject, handles);


% plot the data
plot_data(handles);


% enable export
set(handles.pb_export_data,'enable','on')


function plot_data(handles)


%plot the data
axes(handles.ax_main);
cla
newplot
hold on

c_mat=jet(size(handles.data,2)-1);

params_dat=get(handles.tbl_par,'Data');


for m=2:size(handles.data,2)
    
    %find display scale multiplier
    mult=cell2mat(params_dat(find(strcmp(params_dat(:,1),handles.parameters(m-1)),1),2));
    
    
    
    if get(handles.cb_compress_date_scale,'value')
        plot(handles.data(:,m)*mult,'color',c_mat(m-1,:))
    else
        plot(handles.data(:,1),handles.data(:,m)*mult,'color',c_mat(m-1,:))
    end
end

hold off
grid on

legend(handles.parameters)

if get(handles.cb_compress_date_scale,'value')
    tick_no=8;
    data_sz=size(handles.data,1);
    set(gca,'XTick',linspace(1,data_sz,tick_no))
    set(gca,'XTickLabel',datestr(handles.data(uint16(linspace(1,data_sz,tick_no)),1)))
else
    datetick
end

xlabel('Date')

set(handles.txt_date,'string',['Log start: ' datestr(handles.data(1,1))]);



% --- Executes on button press in cb_load_all_files.
function cb_load_all_files_Callback(hObject, eventdata, handles)
% hObject    handle to cb_load_all_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_load_all_files


% --- Executes on button press in cb_plot_by_file.
function cb_plot_by_file_Callback(hObject, eventdata, handles)
% hObject    handle to cb_plot_by_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_plot_by_file


% --- Executes on button press in pb_export_data.
function pb_export_data_Callback(hObject, eventdata, handles)
% hObject    handle to pb_export_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ffn=get(handles.txt_file,'string');
[path,fname,ext]=fileparts(ffn);

ncols=size(handles.data,2);

fname=[path '\maxiGS911 - data export - ' datestr(now,'yyyy-mm-dd HH-MM-SS') '.csv'];
fid=fopen(fname,'w');

fprintf(fid,'%s\n',cell2mat(['Date,' strcat(handles.parameters(1:end-1),',')' handles.parameters(end)]));
fprintf(fid,['%.9f,' repmat('%.3f,',1,ncols-2) '%.3f\n'],handles.data');

fclose(fid);
msgbox(['Data exported to "' fname '"'])


% --- Executes on button press in cb_compress_date_scale.
function cb_compress_date_scale_Callback(hObject, eventdata, handles)
% hObject    handle to cb_compress_date_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_compress_date_scale

plot_data(handles)


% --- Executes when selected cell(s) is changed in tbl_par.
function tbl_par_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to tbl_par (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)




par_ind=eventdata.Indices(eventdata.Indices(:,2)==1,1);


if isempty(par_ind)
    % if no pars selected disable the extract button
    set(handles.pb_extractd,'enable','off');
    handles.selected_parameters=[];
else
    set(handles.pb_extractd,'enable','on');
    %     handles.par_selected=
    d=get(hObject,'Data');
    handles.selected_parameters=d(par_ind,1);
end


%save the selection
guidata(hObject,handles)
