#  icl::protoip
#  Suardi Andrea [a.suardi@imperial.ac.uk]
#  November - 2014


package require Vivado 1.2014.2

namespace eval ::tclapp::icl::protoip {
    # Export procs that should be allowed to import into other namespaces
    namespace export ip_design_duplicate
}


proc ::tclapp::icl::protoip::ip_design_duplicate {args} {

	  # Summary: Duplicate a project

	  # Argument Usage:
	  # [-from <arg>]:  Original project name to copy
	  # [-to <arg>]: 	New project name
	  # [-usage]: 		Usage information

	  # Return Value:
	  # Duplicated project. If any error(s) occur TCL_ERROR is returned.

	  # Categories: 
	  # xilinxtclstore, protoip
	  

	proc lshift {inputlist} {
      # Summary :
      # Argument Usage:
      # Return Value:
    
      upvar $inputlist argv
      set arg  [lindex $argv 0]
      set argv [lrange $argv 1 end]
      return $arg
    }  
	  
    #-------------------------------------------------------
    # read command line arguments
    #-------------------------------------------------------
    set error 0
    set help 0
    set project_name_oiginal {}
    set project_name_new {}

    set returnString 0
    while {[llength $args]} {
      set name [lshift args]
      switch -regexp -- $name {
		-from -
        {^-o(u(t(p(ut?)?)?)?)?$} {
             set project_name_oiginal [lshift args]
             if {$project_name_oiginal == {}} {
				puts " -E- NO orinal project name specified."
				incr error
             } 
	     }
		-to -
        {^-o(u(t(p(ut?)?)?)?)?$} {
             set project_name_new [lshift args]
             if {$project_name_new == {}} {
				puts " -E- NO new project name specified."
				incr error
             } 
	     }
        -usage -
        {^-u(s(a(ge?)?)?)?$} {
             set help 1
        }
        default {
              if {[string match "-*" $name]} {
                puts " -E- option '$name' is not a valid option. Use the -usage option for more details"
                incr error
              } else {
                puts " -E- option '$name' is not a valid option. Use the -usage option for more details"
                incr error
              }
        }
      }
    }
    

   

if {$error==0} {  

	 if {$project_name_oiginal != {} && $project_name_new != {}} {
		
		set  file_name_from ""
		append file_name_from ".metadata/" $project_name_oiginal "_configuration_parameters.dat"
		set  file_name_to ""
		append file_name_to ".metadata/" $project_name_new "_configuration_parameters.dat"
		
		if {[file exists $file_name_from]==0} {
			set tmp_line ""
			append tmp_line "-E- NO project " $project_name_oiginal " exists."
			puts $tmp_line
			incr error
		} else {
			if {[file exists $file_name_to]==1} {
				set tmp_line ""
				append tmp_line "-E- project " $project_name_new " already exists. Provide an new project name."
				puts $tmp_line
				incr error
			} else {
				#configuration_parameters
				file copy -force $file_name_from $file_name_to
				[::tclapp::icl::protoip::make_ip_configuration_parameters_readme_txt $project_name_new]
				#directives
				set  file_name_from ""
				append file_name_from "ip_design/src/" $project_name_oiginal "_directives.tcl"
				set  file_name_to ""
				append file_name_to "ip_design/src/" $project_name_new "_directives.tcl"
				file copy -force $file_name_from $file_name_to
				#ip_design_build
				set  file_name_from ""
				append file_name_from ".metadata/" $project_name_oiginal "_ip_design_build.tcl"
				set  file_name_to ""
				append file_name_to ".metadata/" $project_name_new "_ip_design_build.tcl"
				file copy -force $file_name_from $file_name_to
				# UPDATE ip_design_build project_name
				set file_read $file_name_to
				set file_write $file_name_to
				set insert_key "# Project name"
				set new_lines ""
				set tmp_line ""
				append tmp_line "set project_name \"$project_name_new\""
				lappend new_lines $tmp_line
				[::tclapp::icl::protoip::addlines $file_read $file_write $insert_key $new_lines]
				#ip_design_test
				set  file_name_from ""
				append file_name_from ".metadata/" $project_name_oiginal "_ip_design_test.tcl"
				set  file_name_to ""
				append file_name_to ".metadata/" $project_name_new "_ip_design_test.tcl"
				file copy -force $file_name_from $file_name_to
				# UPDATE ip_design_test project_name
				set  file_name_to ""
				append file_name_to ".metadata/" $project_name_new "_ip_design_test.tcl"
				set file_read $file_name_to
				set file_write $file_name_to
				set insert_key "# Project name"
				set new_lines ""
				set tmp_line ""
				append tmp_line "set project_name \"$project_name_new\""
				lappend new_lines $tmp_line
				[::tclapp::icl::protoip::addlines $file_read $file_write $insert_key $new_lines]
				
			}
		}
	
	 } else {
		puts " -E- Boths original and new project names have to be specified."
		incr error
	 }
}
	
	



	
	
	
  if {$help} {
      puts [format {
		Usage: ip_design_duplicate
		[-from <arg>]: 	Original project name to copy
		[-to <arg>]: 	New project name
		[-usage|-u]: 	This help message

		Description: Make a copy of a project

		Example:
		tclapp::icl::protoip::ip_design_duplicate -from project_name_original -to project_name_new


	} ]
      # HELP -->
      return {}
    }

    if {$error} {
		puts ""
		return -code error
	} else {
		puts "Project duplicated succesfully."
		puts ""
		return -code ok
	}

    
}



proc ::tclapp::icl::protoip::addlines {file_read file_write insert_key new_lines} {
  # Summary :
  # Argument Usage:
  # Return Value:
  # Categories:
  
	#Read lines of file echo_original.c into variable �lines�
	set f [open $file_read "r"]
	set lines [split [read $f] "\n"]
	close $f

	#Find the insertion index in the reversed list
	set idx [lsearch -regexp [lreverse $lines] $insert_key]
	if {$idx < 0} {
		error "did not find insertion point in $file_read"
	}

	#Insert the lines (I'm assuming they're listed in the variable �linesToInsert�)
	set lines [lreplace $lines end-[expr $idx-1] end-[expr $idx-1] {*}$new_lines]

	#Write the lines back to the file
	set f [open $file_write "w"]
	puts $f [join $lines "\n"]
	close $f
	
	return -code ok
}




