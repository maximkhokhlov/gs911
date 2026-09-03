function varargout = ShowLogTable(varargin)
% SHOWLOGTABLE MATLAB code for ShowLogTable.fig
%      SHOWLOGTABLE, by itself, creates a new SHOWLOGTABLE or raises the existing
%      singleton*.
%
%      H = SHOWLOGTABLE returns the handle to a new SHOWLOGTABLE or the handle to
%      the existing singleton*.
%
%      SHOWLOGTABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHOWLOGTABLE.M with the given input arguments.
%
%      SHOWLOGTABLE('Property','Value',...) creates a new SHOWLOGTABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ShowLogTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ShowLogTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ShowLogTable

% Last Modified by GUIDE v2.5 02-Apr-2014 16:54:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ShowLogTable_OpeningFcn, ...
                   'gui_OutputFcn',  @ShowLogTable_OutputFcn, ...
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


% --- Executes just before ShowLogTable is made visible.
function ShowLogTable_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ShowLogTable (see VARARGIN)

% Choose default command line output for ShowLogTable
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ShowLogTable wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% im=imread('feder ivanovich khokhlov - letnya polyana.JPG');
% axes(handles.ax_main);
% imshow(im)


% --- Outputs from this function are returned to the command line.
function varargout = ShowLogTable_OutputFcn(hObject, eventdata, handles) 
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

if get(handles.cb_load_data,'value')
    set(handles.uitab_headers,'data',[rawData.colheaders;num2cell(rawData.data)]);
else
    set(handles.uitab_headers,'data',rawData.colheaders);
end

if get(handles.cb_adj_clmn_width,'value')
    
    clm_width=cell(1,length(rawData.colheaders));
    
    for n=1:length(rawData.colheaders)
        clm_width{n}=length(rawData.colheaders{n})*get(handles.uitab_headers,'FontSize');
    end
    
    set(handles.uitab_headers,'ColumnWidth',clm_width)
end




% --- Executes on button press in cb_load_data.
function cb_load_data_Callback(hObject, eventdata, handles)
% hObject    handle to cb_load_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_load_data


% --- Executes on button press in cd_adj_clmn_width.
function cd_adj_clmn_width_Callback(hObject, eventdata, handles)
% hObject    handle to cd_adj_clmn_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cd_adj_clmn_width


% --- Executes on button press in cb_adj_clmn_width.
function cb_adj_clmn_width_Callback(hObject, eventdata, handles)
% hObject    handle to cb_adj_clmn_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_adj_clmn_width
