Program RecordAssign;
uses Sysutils, crt, dateutils;

type
	EntryRecord = Record //raw entry record
		cid: longint;
		EnTime: string;
	end;
	
	HolidayEntryRecord = Record
		cid: longint;
		EnTime: string;
	end;
	
	SkuDayEntryRecord = Record
		cid: longint;
		MFEnTime, AFEnTime, MLEnTime, ALEnTime: string;
		MAtt, AAtt: char; //O for on time, L for late, A for absent
		del: boolean; //indicates if that particular record is deleted
	end;
	
const
	DSFname = 'TodayDS.txt';
	ERFname = 'TodayER.dat';
	Timetable = 'Timetable.db'
	StdList = 'StudentIDlist.db'
	
var
	RER: array of EntryRecord; //raw dynamic entry record
	SDER: array of SkuDayEntryRecord; //dynamic school day entry record
	SDERF: file of SkuDayEntryRecord; //file to save a school day entry record
	HER: array of HolidayEntryRecord; //dynamic holiday entry record
	HERF: file of HolidayEntryRecord; //file to save a holiday entry record
	DSF: TextFile; //datasave file
	DSlncount, ReadCount, i, j: integer;
	tmp: string; //placeholder
	holiday, stimetable: boolean; //values indicating if 'today' is a holiday or is of summer timetable
	
Procedure ReadFromDS; //read data from raw datasave and save into raw entry record
begin;
	DSlncount:=0;
	Assign(DSF, DSFname);
	Reset(DSF);
	while not (eof(DSF)) do //find out the no. of records in datasave (a record takes up 2 lines)
	begin
		readln(DSF,tmp);
		DSlncount:=DSlncount+1;
	end;
	DSlncount:=DSlncount/2;
	SetLength(RER, DSlncount); //set the no. of elements of dynamic array RER to no. of records
	for ReadCount:=1 to DSlncount do //assign the data from datasave to RER as array of records
	begin
		readln(DSF, RER[ReadCount].cid);
		readln(DSF, RER[ReadCount].EnTime);
	end;
	Close(DSF);
end;

procedure RERtoWTTER(var k: integer); //raw entry record to winter timetable entry record
begin
	SDER[k].del:= false;
	SDER[k].cid:=NER[k].cid;
	if RER[k].EnTime <= StrToTime('12:35:00') then begin //mark attendance for morning
		SDER[k].MLEnTime:=RER[k].EnTime; //save last entry time in the morning
		if RER[k].EnTime <= StrToTime('08:20:00') then begin
			SDER[k].MAtt := 'O'; //mark on time
		end else begin SDER[k].MAtt := 'L'; end; //mark late 
	end else begin
		if RER[k].EnTime <= StrToTime('15:30:00') then begin //mark attendance for afternoon
			SDER[k].ALEnTime:=RER[k].EnTime; //save last entry time in the afternoon
			if RER[k].EnTime <= StrToTime('13:40:00') then begin
				SDER[k].AAtt := 'O';
			end else begin SDER[k].AAtt := 'L'; end;
		end;
	end;
end;

procedure RERtoSTTER(var k: integer); //raw entry record to summer timetable entry record
begin
	SDER[k].del:= false;
	SDER[k].cid:=NER[k].cid;
	if RER[k].EnTime <= StrToTime('13:35:00') then begin
		SDER[k].MLEnTime:=RER[k].EnTime; //save last entry time 
		if RER[k].EnTime <= StrToTime('07:50:00') then begin
			SDER[k].MAtt := 'O'; //mark on time
		end else begin SDER[k].MAtt := 'L'; end; //mark late 
	end ;
end;

procedure MergeSDER; //merge school day entry records which have the same card id
begin
	for i:=1 to DSlncount do
	SDER[i].MFEnTime := SDER[i].MLEnTime;
	SDER[i].AFEnTime := SDER[i].ALEnTime;
	begin
		for j:= i+1 to DSlncount do
		begin
			if not SDER[i].del then
			begin 
				if SDER[i].cid=SDER[j].cid then
				begin
					if SDER[i].MLEnTime <> SDER[j].MLEnTime then
					begin 
						if SDER[i].MLEnTime < SDER[j].MLEnTime then
						begin
							SDER[i].MLEnTime := SDER[j].MLEnTime;
							SDER[i].MAtt := SDER[j].MAtt;
						end else begin
							SDER[i].MFEnTime := SDER[j].MFEnTime;
						end;
						SDER[j].del := true;
					end else if SDER[i].ALEnTime <> SDER[j].ALEnTime then
					begin
						if SDER[i].ALEnTime < SDER[j].ALEnTime then
						begin
							SDER[i].ALEnTime := SDER[j].ALEnTime;
							SDER[i].AAtt := SDER[j].AAtt;
						end else begin
							SDER[i].AFEnTime := SDER[j].AFEnTime;
						end;
						SDER[j].del := true;
					end;
				end;
			end;
		end;
	end;
end;


begin
	ReadFromDS;
	SetLength(HER, DSlncount); //set the no. of elements of dynamic array HER to no. of records
	SetLength(SDER, DSlncount); //set the no. of elements of dynamic array SDER to no. of records
	
	Reset(Timetable);
	{read if holiday then read if stimetable, save them to boolean respectively}
	if holiday then
		try
			for ReadCount:=1 to DSlncount do
			begin RERtoHER(ReadCount); end;
			Assign(HERF, ERFname);
			Rewrite(HERF);
			for i:=1 to DSlncount do
				begin
					{save to database}
				end;
			Close(HERF);
		except
			on E: EInOutError do //catch the error
				writeln('File handling error occurred. Details: ', E.ClassName, '/',E.Message);
			end
	else try
			if stimetable then begin
				for ReadCount:=1 to DSlncount do
					begin RERtoSTTER(ReadCount); end;
			end
			else begin
				for ReadCount:=1 to DSlncount do
					begin RERtoWTTER(ReadCount); end;
			end;
			MergeSDER; 
			Assign(SDERF, ERFname);
			Rewrite(SDERF);
			for i:=1 to DSlncount do
			begin
				if not SDER[i].del then
				begin
					{comparing card id with database to find student id, 
					then save the SDER records into database according to student id}
				end;
			end;
			Close(SDERF);
		except
			on E: EInOutError do //catch the error
				writeln('File handling error occurred. Details: ', E.ClassName, '/',E.Message);
			end;
end.