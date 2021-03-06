Program DataSave;
uses Sysutils, crt; //sysutils is for file handling functions and Time function, crt is for error catching functions

const
	DSFname = 'C:\Users\Cyrus\Desktop\TodayDS.txt'; //file path for data save, change according to situation
	
var
	DSout: TextFile; //declare a text file for data save output
	cardid: string; //the card id to be read into
	
begin
	Assign(DSout, DSFname); //to declare the text output 'DSout' to the file path
	
	//currently the program only do the following procedure once, 
	//remove comment delimiter for repeat until loop if it is to be run forever

	repeat
		readln(cardid);
		try
			Append(DSout); //to write to the file without deleting previous records
			writeln(DSout, cardid); //to enter the card id
			writeln(DSout, Time); //to enter the current time in a way readable by computer
			Close(DSout); //to save the file
		except
			on E: EInOutError do //to catch the error
				writeln('File handling error occurred. Details: ', E.ClassName, '/',E.Message);
			end;
	until (LowerCase(cardid) = 'exit') or (LowerCase(cardid) = 'stop') or (LowerCase(cardid) = 'terminate');
end.
