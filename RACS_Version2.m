function varargout = Automation_ver3_4(varargin)
% AUTOMATION_VER3_4 MATLAB code for Automation_ver3_4.fig
%      AUTOMATION_VER3_4, by itself, creates a new AUTOMATION_VER3_4 or raises the existing
%      singleton*.
%
%      H = AUTOMATION_VER3_4 returns the handle to a new AUTOMATION_VER3_4 or the handle to
%      the existing singleton*.
%
%      AUTOMATION_VER3_4('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AUTOMATION_VER3_4.M with the given input arguments.
%
%      AUTOMATION_VER3_4('Property','Value',...) creates a new AUTOMATION_VER3_4 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Automation_ver3_4_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Automation_ver3_4_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Automation_ver3_4

% Last Modified by GUIDE v2.5 12-Apr-2018 12:23:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Automation_ver3_4_OpeningFcn, ...
                   'gui_OutputFcn',  @Automation_ver3_4_OutputFcn, ...
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


% --- Executes just before Automation_ver3_4 is made visible.
function Automation_ver3_4_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Automation_ver3_4 (see VARARGIN)

% Choose default command line output for Automation_ver3_4

handles.output = hObject;

axes(handles.Lab_logo);
imshow('Logo.jpg');

% axes(handles.mit_logo);
% imshow('MIT_logo.jpg');

axes(handles.ETH_logo);
imshow('ETH_logo.jpg');

% Call the LabSpec ActiveX
global LabSpec Motor Motor2
LabSpec = actxcontrol('NFACTIVEX.NFActiveXCtrl.1', [15 15 410 390]);

% Call & open the optical shutter
Motor=serial('COM2');
Motor.Terminator = 'CR';
fopen(Motor);
fprintf(Motor,'mode=1');
fprintf(Motor,'ens');

Motor2=serial('COM6');
Motor2.Terminator = 'CR';
fopen(Motor2);
fprintf(Motor2,'mode=1');
fprintf(Motor2,'ens');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Automation_ver3_4 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Automation_ver3_4_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in togglebutton1.
function togglebutton1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton1


% --- Executes on button press in Start_RACS.
function Start_RACS_Callback(hObject, eventdata, handles)
% hObject    handle to Start_RACS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Version 3_4 modifications
% 1. The system calculates PC and PL simultaneously
% 2. The system calculates PC again at the release location
%    (to check whether there is a cell loss during the stage movement)
% 3. Number '2' has been deleted to reduce the photophoretic 
%     cell damage issue during the second Raman measurements

global LabSpec Motor Motor2 Mode IntegrationTime AccumulationNum AccumulationNum_2 AcqFrom AcqTo
global Dis_lower Dis_upper Crit_lower Crit_upper CD_lower CD_upper sum_Dis
global loopFlag threshold_1 threshold_2 A

loopFlag = true;
threshold_1 = 1.1;          % threshold to identify the cell inside of optical trap (note: 1.0)
threshold_2 = 0.87;          % threshold to distinguish labeled and unlabeled cell (note: 0.87)

datetime = datestr(clock, 31);
datetime = strrep(datetime,':','_');               % Replace colon with underscore
filename1 = ['Spectra_Labeled_' datetime '.txt'];
filename2 = ['Spectra_Unlabeled_' datetime '.txt'];
filename3 = ['PCPL_Labeled_' datetime '.txt'];
filename4 = ['PCPL_Unlabeled_' datetime '.txt'];

fp=fopen(filename1,'a+');
fprintf(fp,'Raman_shift(cm-1) ');
fprintf(fp,'%f ',A);
fprintf(fp,'\n');

fp2=fopen(filename2,'a+');
fprintf(fp2,'Raman_shift(cm-1) ');
fprintf(fp2,'%f ',A);
fprintf(fp2,'\n');

fp3=fopen(filename3,'a+');
fprintf(fp3,'Cell# PC_input PL_input PC PL\n');

fp4=fopen(filename4,'a+');
fprintf(fp4,'Cell# PC_input PL_input PC PL\n');

fprintf(Motor,'ens');
pause(1.0)
fprintf(Motor,'ens');

IniPositionY = 0;
PositionToGoY = -270;             % Move the stage 270 um in y-direction
    
while true
    while true
        pause(0.0001)
        if(loopFlag == false)
            break;
        end
        LabSpec.Acq(Mode,IntegrationTime,AccumulationNum_2,AcqFrom,AcqTo);
        SpectrumID = -3;
        while SpectrumID <= 0
            SpectrumID = LabSpec.GetAcqID();
        end
        SpectrumValues = LabSpec.GetValueSimple(SpectrumID,'XYData',0,5);
%         C = cell2mat(SpectrumValues(1,:)');
        D = cell2mat(SpectrumValues(2,:)');
%         D = D/norm(D,inf);
        sum_Dis2 = 0.0;
        for i = Dis_lower:Dis_upper
            sum_Dis2 = sum_Dis2 + D(i);
        end
        ratio = sum_Dis2/sum_Dis;
        set(handles.Threshold_cell_output,'String',ratio);
        
        if ratio > threshold_1
            % Calculation of CD/(Criterion+CD) value Note, Criterion (1850-1900 cm-1) and CD (2040-2300 cm-1)
            sum_CD = 0.0;
            sum_Crit = 0.0;
            base = 0.0;
            for i = CD_lower:CD_upper
                sum_CD = sum_CD + (D(i)-base);
            end
            for j = Crit_lower:Crit_upper
                sum_Crit = sum_Crit + (D(j)-base);
            end
                        
            ratio_2 = sum_CD/(sum_CD + sum_Crit);
            set(handles.Threshold_target_output,'String',ratio_2);
            
            result_1 = str2num(get(handles.Result_1,'String'))+1;
            set(handles.Result_1,'String',result_1);       % counting the number of analyzed cell
            
            % optical shutter operations
            % if the cell is the good cell, move the stage perpendicular 
            % to the flow direction and release the cell.
            % otherwise, release the cell in the streamline to the waste outlet.
            
            if ratio_2 >= threshold_2                      % in case labeled cell
                fprintf(Motor2,'ens');
                pause(0.1)
                Ret = LabSpec.MoveMotor('Y',PositionToGoY,'',0);
                set(handles.Stage_y,'String',PositionToGoY);
                pause(0.1)
                fprintf(Motor,'ens');
                Ret = LabSpec.MoveMotor('Y',IniPositionY,'',0);
                set(handles.Stage_y,'String',IniPositionY);
                                
                % Update the Results window and write a datum
                result_2 = str2num(get(handles.Result_2,'String'))+1;
                set(handles.Result_2,'String',result_2);
                fprintf(fp,'cell#_%d ',result_2);
                fprintf(fp,'%f ',D);
                fprintf(fp,'\n');
                fprintf(fp3,'%d %f %f %f %f \n',result_2,threshold_1,threshold_2,ratio,ratio_2);
                
                fprintf(Motor,'ens');
                fprintf(Motor2,'ens');
            else                                          % in case unlabeled cell
                fprintf(Motor,'ens');
                
                % Update the Results window and write a datum
                result_3 = str2num(get(handles.Result_3,'String'))+1;
                set(handles.Result_3,'String',result_3);
                fprintf(fp2,'cell#_%d ',result_3);
                fprintf(fp2,'%f ',D);
                fprintf(fp2,'\n');
                fprintf(fp4,'%d %f %f %f %f \n',result_3,threshold_1,threshold_2,ratio,ratio_2);
                
                pause(0.2)
                fprintf(Motor,'ens');
            end
            % Update the Results window
            result_2 = str2num(get(handles.Result_2,'String'));
            result_4 = result_2./result_1;
            set(handles.Result_4,'String',result_4);
                                    
            % Draw the figure in lower window
            axes(handles.Label_2);
            plot(A, D, 'b-', 'LineWidth', 1)
            legend(sprintf('Acquisition time = %.2f s',IntegrationTime))
            title('Measured spectra')
            xlabel('Raman shift (cm-1)')
            ylabel('Intensity (AU)')
            axis([400 3300 -inf inf])
            grid on
            break
        end
        pause(0.0001)
    end
    
    pause(0.0001)
    if(loopFlag == false)
        fclose(fp);
        fclose(fp2);
        fclose(fp3);
        fclose(fp4);
        break;
    end
        
end

% --- Executes on button press in Exit.
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global LabSpec Motor Motor2
% Close & evacuate the optical shutter
fprintf(Motor,'ens');
fclose(Motor);
delete(Motor);

fprintf(Motor2,'ens');
fclose(Motor2);
delete(Motor2);

% Close & evacuate the LabSpec
delete(LabSpec);

hf = findobj('Name','gui');
close(hf)


function Result_2_Callback(hObject, eventdata, handles)
% hObject    handle to Result_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Result_2 as text
%        str2double(get(hObject,'String')) returns contents of Result_2 as a double


% --- Executes during object creation, after setting all properties.
function Result_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Result_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Result_3_Callback(hObject, eventdata, handles)
% hObject    handle to Result_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Result_3 as text
%        str2double(get(hObject,'String')) returns contents of Result_3 as a double


% --- Executes during object creation, after setting all properties.
function Result_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Result_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Result_4_Callback(hObject, eventdata, handles)
% hObject    handle to Result_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Result_4 as text
%        str2double(get(hObject,'String')) returns contents of Result_4 as a double


% --- Executes during object creation, after setting all properties.
function Result_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Result_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Result_1_Callback(hObject, eventdata, handles)
% hObject    handle to Result_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Result_1 as text
%        str2double(get(hObject,'String')) returns contents of Result_1 as a double


% --- Executes during object creation, after setting all properties.
function Result_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Result_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Stage_y_Callback(hObject, eventdata, handles)
% hObject    handle to Stage_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Stage_y as text
%        str2double(get(hObject,'String')) returns contents of Stage_y as a double


% --- Executes during object creation, after setting all properties.
function Stage_y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Stage_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Video_on.
function Video_on_Callback(hObject, eventdata, handles)
% hObject    handle to Video_on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabSpec;
% Start the Video
Ret = LabSpec.Video(0);
% while 1
%     IDVideo = LabSpec.Video(2);
% end


% --- Executes on button press in Video_off.
function Video_off_Callback(hObject, eventdata, handles)
% hObject    handle to Video_off (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global LabSpec;
% Stop the Video
Ret = LabSpec.Video(1);


% --- Executes on mouse press over axes background.
function Label_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function Label_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function Label_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate Label


% --- Executes on button press in Spectra_calibration.
function Spectra_calibration_Callback(~, eventdata, handles)
% hObject    handle to Spectra_calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Acquire the Spectra for the initialization (5 times average)
global LabSpec Mode IntegrationTime AccumulationNum AccumulationNum_2 AcqFrom AcqTo
global A Motor
Mode = 10;                  % ACQ_SPECTRUM + ACQ_AUTO_SHOW
IntegrationTime = 0.3;      % 0.3 s
AccumulationNum = 10;       % accumulations = 10 ; averaging the 10 spectra
AccumulationNum_2 = 1;
AcqFrom = LabSpec.ConvertUnit(400,0);
AcqTo = LabSpec.ConvertUnit(3300,0);

IniPositionY = 0;
PositionToGoY = -70;             % Move the stage 210 um in y-direction
fprintf(Motor,'ens');
pause(0.5)
Ret = LabSpec.MoveMotor('Y',PositionToGoY,'',0);
set(handles.Stage_y,'String',PositionToGoY);
fprintf(Motor,'ens');
pause(1.0)

SpectrumID = -3;
LabSpec.Acq(Mode,IntegrationTime,AccumulationNum,AcqFrom,AcqTo);
while SpectrumID <= 0
    SpectrumID = LabSpec.GetAcqID();
end
SpectrumValues = LabSpec.GetValueSimple(SpectrumID,'XYData',0,5);

A = (cell2mat(SpectrumValues(1,:)))';
B = (cell2mat(SpectrumValues(2,:)))';
% B = B/norm(B,inf);
% B_2 = (cell2mat(SpectrumValues_2(2,:)))';
% B_2 = B_2/norm(B_2,inf);

% Calculate the Discriminant, Criteron, and CD regions
% Note, Discriminant (1620-1670 cm-1), Criterion (1850-1900 cm-1), and CD (2040-2300 cm-1)
[M N] = size(A);
global Dis_lower Dis_upper Crit_lower Crit_upper CD_lower CD_upper sum_Dis

for i=1:M
    if A(i) > 1620
        Dis_lower = i;
        break
    end
end

for i=1:M
    if A(i) > 1670
        Dis_upper = i-1;
        break
    end
end

sum_Dis = 0;
for i=Dis_lower:Dis_upper
    sum_Dis = sum_Dis + B(i);
end

for i=1:M
    if A(i) > 1850
        Crit_lower = i;
        break
    end
end

for i=1:M
    if A(i) > 1900
        Crit_upper = i-1;
        break
    end
end

for i=1:M
    if A(i) > 2040
        CD_lower = i;
        break
    end
end

for i=1:M
    if A(i) > 2300
        CD_upper = i-1;
        break
    end
end

datetime = datestr(clock, 31);
datetime = strrep(datetime,':','_');                % Replace colon with underscore
filename = ['Calibration_' datetime '.l6s'];
Ret = LabSpec.Save(SpectrumID,filename,'l6s');     % save the spectrum

% Plot the calibration spectrum
axes(handles.Label);
plot(A, B, 'r-', 'LineWidth', 1)
legend(sprintf('Acquisition time = %.2f s', IntegrationTime))
title(sprintf('Calibration spectrum (averaged over %d measurements)', AccumulationNum))
xlabel('Raman shift (cm-1)')
ylabel('Intensity (AU)')
axis([400 3300 -inf inf])
grid on

set(handles.Stage_y,'String',IniPositionY);
Ret = LabSpec.MoveMotor('Y',IniPositionY,'',0);


% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loopFlag

loopFlag = false;


function Threshold_cell_input_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold_cell_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Threshold_cell_input as text
%        str2double(get(hObject,'String')) returns contents of Threshold_cell_input as a double

global threshold_1 Motor
threshold_1 = str2double(get(handles.Threshold_cell_input,'String'));
fprintf(Motor,'ens');
pause(0.2)
fprintf(Motor,'ens');


% --- Executes during object creation, after setting all properties.
function Threshold_cell_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold_cell_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Threshold_target_input_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold_target_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Threshold_target_input as text
%        str2double(get(hObject,'String')) returns contents of Threshold_target_input as a double

global threshold_2 Motor
threshold_2 = str2double(get(handles.Threshold_target_input,'String'));
fprintf(Motor,'ens');
pause(0.2)
fprintf(Motor,'ens');

% --- Executes during object creation, after setting all properties.
function Threshold_target_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold_target_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Threshold_cell_output_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold_cell_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Threshold_cell_output as text
%        str2double(get(hObject,'String')) returns contents of Threshold_cell_output as a double


% --- Executes during object creation, after setting all properties.
function Threshold_cell_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold_cell_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Threshold_target_output_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold_target_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Threshold_target_output as text
%        str2double(get(hObject,'String')) returns contents of Threshold_target_output as a double


% --- Executes during object creation, after setting all properties.
function Threshold_target_output_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold_target_output (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
datetime = datestr(clock, 31);
datetime = strrep(datetime,':','_');                % Replace colon with underscore
saveas(gcf,['Window_snapshot_' datetime '.bmp'])



function Result_5_Callback(hObject, eventdata, handles)
% hObject    handle to Result_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Result_5 as text
%        str2double(get(hObject,'String')) returns contents of Result_5 as a double


% --- Executes during object creation, after setting all properties.
function Result_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Result_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
