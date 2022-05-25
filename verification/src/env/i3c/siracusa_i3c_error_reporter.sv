class error_reporter extends QUESTA_MVC::questa_mvc_reporter;

  bit protocol_err;

  // Function: new
  //
  // The constructor for the reporter object. 
  //
  function new(string n = "my_reporter");
    super.new(n);
  endfunction

  // Function: report_message
  //
  // An overload for the virtual function called by the QVIP when it issues a report.
  //
  // category     - A string giving a category for the report.
  // fileName     - The name of the file from which the report was issued.
  // lineNo       - The line number in the file at which the report was issued.
  // objectName   - The type of object from which the report was issued.
  // instanceName - The name of the instance from which the report was issued.
  // error_no     - An error number associated with the type of report.
  // typ          -  A string giving the severity of the report (INFO, WARNING, ERROR, FATAL).
  // mess         - The message string.

  function void report_message(string category, string fileName,int lineNo,string objectName, string instanceName, string error_no,string typ, string mess);

    if(typ == "ERROR") 
      protocol_err = 1;
  endfunction

endclass
