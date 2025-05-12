function[header,data] = read_trc(filename)
%% Function to read Micromed TRC files into Matlab
%  Daniel Bush, UCL (2024) drdanielbush@gmail.com
%
%  This code borrows heavily from the Fieldtrip read_micromed_trc function:
%  https://github.com/fieldtrip/fieldtrip/blob/master/fileio/private/read_micromed_trc.m
%
%  Inputs:
%  filename - full path and filename for a *.TRC file
%
%  Outputs:
%  header   - anonymised header information
%  data     - channel x sample matrix of EEG traces


%% First, open the file, assign some memory
[fid, msg]  = fopen(filename, 'r');
if fid < 0
    disp(['ERROR: ' msg]); return
else
    header  = struct;
end
clear msg


%% Second, read the header information
fseek(fid,128,-1);
day         = fread(fid,1,'char');
month       = fread(fid,1,'char');
year        = fread(fid,1,'char');
header.date = [int2str(day) '.' int2str(month) '.' int2str(1900+year)]; clear day month year

fseek(fid,138,-1);
Data_Start_Offset               = fread(fid,1,'uint32');
header.nChan                    = fread(fid,1,'uint16');
[~]                             = fread(fid,1,'uint16');
header.fS                       = fread(fid,1,'uint16');
bitRate                         = fread(fid,1,'uint16');

fseek(fid,184,'bof');
OrderOff                        = fread(fid,1,'ulong');
fseek(fid,OrderOff,'bof'); clear OrderOff
vOrder                          = zeros(header.nChan,1);
for c = 1 : header.nChan, vOrder(c) = fread(fid,1,'ushort'); end

fseek(fid,200,'bof');
ElecOff                         = fread(fid,1,'ulong');
for c                           = 1 : header.nChan
    fseek(fid,ElecOff+128*vOrder(c),'bof');
    if ~fread(fid,1,'uchar'), continue; end
    header.elec(c).bip          = fread(fid,1,'uchar');
    header.elec(c).Name         = deblank(char(fread(fid,6,'char'))');
    header.elec(c).Name(isspace(header.elec(c).Name)) = []; % remove spaces
    header.elec(c).Ref          = deblank(char(fread(fid,6,'char'))');
    header.elec(c).LogicMin     = fread(fid,1,'long');
    header.elec(c).LogicMax     = fread(fid,1,'long');
    header.elec(c).LogicGnd     = fread(fid,1,'long');
    header.elec(c).PhysMin      = fread(fid,1,'long');
    header.elec(c).PhysMax      = fread(fid,1,'long');
    Unit                        = fread(fid,1,'ushort');
    switch Unit
        case -1
            header.elec(c).Unit = 'nV';
        case 0
            header.elec(c).Unit = 'uV';
        case 1
            header.elec(c).Unit = 'mV';
        case 2
            header.elec(c).Unit = 'V';
        case 100
            header.elec(c).Unit = '%';
        case 101
            header.elec(c).Unit = 'bpm';
        case 102
            header.elec(c).Unit = 'Adim.';
    end
    clear Unit

    fseek(fid,ElecOff+128*vOrder(c)+44,'bof');
    header.elec(c).FsCoeff      = fread(fid,1,'ushort');
    fseek(fid,ElecOff+128*vOrder(c)+90,'bof');
    header.elec(c).XPos         = fread(fid,1,'float');
    header.elec(c).YPos         = fread(fid,1,'float');
    header.elec(c).ZPos         = fread(fid,1,'float');
    fseek(fid,ElecOff+128*vOrder(c)+102,'bof');
    header.elec(c).Type         = fread(fid,1,'ushort');
end
header.elec = header.elec; clear ElecOff c vOrder


%% Finally, read in the data
fseek(fid,Data_Start_Offset,-1);
datbeg      = ftell(fid);
fseek(fid,0,1);
datend      = ftell(fid);
nSmp        = (datend-datbeg)/(bitRate*header.nChan);
if rem(nSmp, 1)~=0
    nSmp    = floor(nSmp);
end
% data        = nan(header.nChan,nSmp);
fseek(fid,Data_Start_Offset,-1); clear Data_Start_Offset
fseek(fid, 0, 0);
switch bitRate
    case 1
        data  = fread(fid, [header.nChan nSmp], 'uint8');
    case 2
        data  = fread(fid, [header.nChan nSmp], 'uint16');
    case 4
        data  = fread(fid, [header.nChan nSmp], 'uint32');
end

for c       = 1 : header.nChan
    data(c,:)                   = ((data(c,:)-header.elec(c).LogicGnd)/(header.elec(c).LogicMax-header.elec(c).LogicMin+1)) * (header.elec(c).PhysMax-header.elec(c).PhysMin);
end
clear bitRate c datbeg datend fid

end