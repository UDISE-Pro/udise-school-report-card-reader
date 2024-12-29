class SchoolReportParser
  require 'pdf-reader'
  require 'yaml'

  def self.extract_to_text(pdf_path)
    raise ArgumentError, "PDF file not found" unless File.exist?(pdf_path)
    
    reader = PDF::Reader.new(pdf_path)
    content = reader.pages.map(&:raw_content).join("\n")
    
    # Create text file with same name as PDF
    txt_path = pdf_path.sub(/\.pdf$/i, '.txt')
    File.write(txt_path, content)
    
    # Create compressed version
    compressed_content = compress_content(content)
    compressed_path = pdf_path.sub(/\.pdf$/i, '_compressed.txt')
    File.write(compressed_path, compressed_content)
    
    # Extract data points to YAML
    data_points = extract_data_points(compressed_content)
    yaml_path = pdf_path.sub(/\.pdf$/i, '.yml')
    File.write(yaml_path, data_points.to_yaml)
    
    [txt_path, compressed_path, yaml_path]
  end

  private

  def self.compress_content(content)
    compressed = []
    current_block = []
    in_bt_block = false
    current_text = ""

    content.each_line do |line|
      if line.include?('BT')
        in_bt_block = true
        current_block = []
        current_text = ""
      elsif line.include?('ET')
        in_bt_block = false
        current_text = current_block.join("")
        compressed << current_text unless current_text.empty?
      elsif in_bt_block && line =~ /\((.*?)\)\s*Tj/
        # Extract text between (...) followed by Tj
        text = $1.strip
        if text =~ /^(?:Non|Residenti|al)$/
          # Special handling for split residential text
          current_text += text
          current_block << text
        else
          if !current_text.empty?
            compressed << current_text
          end
          current_text = text
          current_block = [text]
        end
      end
    end

    compressed.reject(&:empty?).join("\n")
  end

  def self.extract_data_points(compressed_content)
    lines = compressed_content.split("\n").map(&:strip)
    
    data = {
      'basic_info' => {},
      'location' => {},
      'school_details' => {
        'recognition' => {},
        'affiliation' => {},
        'shifts' => {},
        'special_focus' => {}
      },
      'infrastructure' => {
        'toilets' => {
          'boys' => {
            'total' => 0,
            'functional' => 0,
            'cwsn' => 0,
            'urinals' => 0
          },
          'girls' => {
            'total' => 0,
            'functional' => 0,
            'cwsn' => 0,
            'urinals' => 0
          }
        },
        'classrooms' => {
          'count' => {},
          'condition' => {},
          'special_rooms' => {}
        },
        'digital_facilities' => {},
        'other_facilities' => {},
        'building' => {
          'details' => {},
          'accessibility' => {},
          'safety' => {}
        },
        'furniture' => {
          'count' => {},
          'condition' => {}
        },
        'library' => {
          'details' => {},
          'books' => {},
          'staff' => {}
        }
      },
      'teachers' => {
        'count_by_level' => {},
        'qualifications' => {
          'academic' => {},
          'professional' => {}
        },
        'demographics' => {},
        'training' => {
          'computer' => {},
          'service' => {},
          'special' => {}
        },
        'age_distribution' => {},
        'assignments' => {
          'teaching' => {},
          'non_teaching' => {}
        },
        'classes_taught' => {},
        'attendance' => {}
      },
      'students' => {
        'enrollment' => {
          'general' => {},
          'by_class' => {
            'pre_primary' => { 'boys' => 0, 'girls' => 0 },
            'class_1' => { 'boys' => 0, 'girls' => 0 },
            'class_2' => { 'boys' => 0, 'girls' => 0 },
            'class_3' => { 'boys' => 0, 'girls' => 0 },
            'class_4' => { 'boys' => 0, 'girls' => 0 },
            'class_5' => { 'boys' => 0, 'girls' => 0 },
            'class_6' => { 'boys' => 0, 'girls' => 0 },
            'class_7' => { 'boys' => 0, 'girls' => 0 },
            'class_8' => { 'boys' => 0, 'girls' => 0 },
            'class_9' => { 'boys' => 0, 'girls' => 0 },
            'class_10' => { 'boys' => 0, 'girls' => 0 },
            'class_11' => { 'boys' => 0, 'girls' => 0 },
            'class_12' => { 'boys' => 0, 'girls' => 0 }
          },
          'by_social_category' => {
            'general' => { 'boys' => 0, 'girls' => 0 },
            'sc' => { 'boys' => 0, 'girls' => 0 },
            'st' => { 'boys' => 0, 'girls' => 0 },
            'obc' => { 'boys' => 0, 'girls' => 0 }
          },
          'cwsn' => {
            'by_type' => {},
            'facilities' => {}
          },
          'rte' => {
            'section_12' => {},
            'ews' => {}
          },
          'minority' => {
            'by_religion' => {}
          }
        },
        'facilities' => {
          'general' => {},
          'scholarships' => {
            'government' => {},
            'private' => {}
          },
          'incentives' => {
            'books' => {},
            'uniform' => {},
            'transport' => {}
          }
        },
        'attendance' => {
          'by_class' => {},
          'average' => {}
        },
        'performance' => {
          'by_class' => {},
          'board_results' => {}
        }
      },
      'academic' => {
        'medium_of_instruction' => {},
        'inspections' => {
          'visits' => {},
          'officers' => {},
          'reports' => {}
        },
        'hours' => {
          'instructional' => {},
          'working' => {},
          'shifts' => {}
        },
        'subjects' => {
          'languages' => {},
          'core' => {},
          'electives' => {}
        },
        'assessments' => {
          'cce' => {
            'implementation' => {},
            'records' => {}
          },
          'board_results' => {
            'class_10' => {},
            'class_12' => {}
          }
        },
        'vocational' => {
          'courses' => {},
          'trainers' => {},
          'facilities' => {}
        },
        'sports' => {
          'facilities' => {},
          'equipment' => {},
          'instructors' => {}
        }
      },
      'facilities' => {
        'residential' => {
          'details' => {},
          'hostel' => {
            'boys' => {},
            'girls' => {},
            'staff' => {}
          },
          'mess' => {
            'kitchen' => {},
            'dining' => {}
          }
        },
        'basic' => {
          'water' => {
            'source' => {},
            'quality' => {},
            'storage' => {}
          },
          'electricity' => {
            'connection' => {},
            'backup' => {},
            'renewable' => {}
          },
          'sanitation' => {
            'toilets' => {},
            'cleaning' => {},
            'waste' => {}
          },
          'safety' => {
            'building' => {},
            'playground' => {},
            'transport' => {}
          }
        },
        'safety' => {
          'fire' => {
            'equipment' => {},
            'training' => {}
          },
          'emergency' => {
            'exits' => {},
            'procedures' => {}
          },
          'security' => {
            'personnel' => {},
            'equipment' => {}
          }
        },
        'medical' => {
          'checkups' => {
            'regular' => {},
            'special' => {}
          },
          'first_aid' => {
            'equipment' => {},
            'training' => {}
          },
          'staff' => {
            'nurse' => {},
            'doctor' => {}
          }
        },
        'anganwadi' => {
          'center' => {},
          'staff' => {},
          'children' => {}
        }
      },
      'committees' => {
        'smc' => {
          'details' => {
            'composition' => {},
            'meetings' => {}
          },
          'activities' => {},
          'funds' => {}
        },
        'smdc' => {
          'details' => {
            'composition' => {},
            'meetings' => {}
          },
          'activities' => {},
          'funds' => {}
        },
        'pta' => {
          'details' => {},
          'meetings' => {},
          'activities' => {}
        }
      },
      'grants' => {
        'received' => {
          'composite' => {
            'amount' => {},
            'date' => {}
          },
          'maintenance' => {
            'amount' => {},
            'purpose' => {}
          },
          'development' => {
            'amount' => {},
            'purpose' => {}
          }
        },
        'expenditure' => {
          'composite' => {
            'amount' => {},
            'details' => {}
          },
          'maintenance' => {
            'amount' => {},
            'details' => {}
          },
          'development' => {
            'amount' => {},
            'details' => {}
          }
        },
        'utilization' => {
          'certificates' => {},
          'reports' => {}
        }
      }
    }

    # Add new sections to the data structure
    data['academic']['subjects']['languages']['details'] = {}
    data['academic']['subjects']['core']['details'] = {}
    data['academic']['subjects']['electives']['details'] = {}
    
    data['students']['attendance']['monthly'] = {}
    data['students']['attendance']['term_wise'] = {}
    
    data['teachers']['workload'] = {
      'teaching_hours' => {},
      'non_teaching_hours' => {},
      'by_subject' => {}
    }
    
    data['infrastructure']['classrooms']['usage'] = {
      'regular' => {},
      'labs' => {},
      'special_rooms' => {}
    }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip
      next_next_line = lines[i + 2]&.strip

      case line
      # Basic Info
      when "UDISE CODE"
        if next_line && (match = next_line.match(/(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{3})/))
          data['basic_info']['udise_code'] = match[1..5].join('')
        end
      when "School Name"
        if next_line && next_line.include?("CARMEL")
          data['basic_info']['name'] = next_line
        end
      when /Academic Year.*:\s*(\d{4}-\d{2})/
        data['basic_info']['academic_year'] = $1
      
      # Location
      when "State"
        data['location']['state'] = next_line if next_line && !next_line.match?(/District/)
      when "District"
        data['location']['district'] = next_line if next_line && !next_line.match?(/Block/)
      when "Block"
        data['location']['block'] = next_line if next_line && !next_line.match?(/Rural/)
      when "Rural / Urban"
        data['location']['area_type'] = next_line if next_line && !next_line.match?(/Cluster/)
      when "Pincode"
        data['location']['pincode'] = next_line if next_line && next_line.match?(/^\d+$/)
      when "Ward"
        data['location']['ward'] = next_line if next_line && !next_line.match?(/Mohalla/)
      when "Cluster"
        data['location']['cluster'] = next_line if next_line && !next_line.match?(/Ward/)
      when "Municipality"
        data['location']['municipality'] = next_line if next_line && !next_line.match?(/Assembly/)
      when "Assembly Const."
        data['location']['assembly_constituency'] = next_line if next_line && !next_line.match?(/Parl/)
      when "Parl. Constituency"
        data['location']['parliamentary_constituency'] = next_line if next_line && !next_line.match?(/School/)
      
      # School Details
      when "School Category"
        data['school_details']['category'] = next_line if next_line && !next_line.match?(/School Management/)
      when "School Management"
        data['school_details']['management'] = next_line if next_line && !next_line.match?(/School Type/)
      when "School Type"
        data['school_details']['type'] = next_line if next_line && !next_line.match?(/Lowest/)
      when "Lowest & Highest Class"
        data['school_details']['class_range'] = next_line if next_line && !next_line.match?(/Pre Primary/)
      when "Pre Primary"
        data['school_details']['pre_primary'] = next_line if next_line && !next_line.match?(/Medium/)
      when "Year of Establishment"
        data['school_details']['established'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Pri."
        data['school_details']['recognition']['primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Upr.Pri."
        data['school_details']['recognition']['upper_primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Sec."
        data['school_details']['recognition']['secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Higher Sec."
        data['school_details']['recognition']['higher_secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Affiliation Board-Sec"
        data['school_details']['affiliation']['secondary'] = next_line if next_line && !next_line.match?(/Affiliation Board-HSec/)
      when "Affiliation Board-HSec"
        data['school_details']['affiliation']['higher_secondary'] = next_line if next_line && !next_line.match?(/Is this/)
      when "Building Status"
        data['infrastructure']['building']['details']['status'] = next_line if next_line && !next_line.match?(/Boundary/)
      when "Is this a Shift School?"
        data['school_details']['shifts']['has_shifts'] = next_line if next_line && !next_line.match?(/Building/)
      when "Is Special School for CWSN?"
        data['school_details']['is_special_school'] = next_line if next_line && !next_line.match?(/Availability/)
      
      # Infrastructure - Building
      when "Boundary wall"
        data['infrastructure']['building']['details']['boundary_wall'] = next_line if next_line && !next_line.match?(/No\.of/)
      when "No.of Building Blocks"
        data['infrastructure']['building']['details']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Pucca Building Blocks"
        data['infrastructure']['building']['details']['pucca_blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Availability of Ramps"
        data['infrastructure']['building']['accessibility']['ramps'] = next_line if next_line && !next_line.match?(/Availability of Hand/)
      when "Availability of Handrails"
        data['infrastructure']['building']['accessibility']['handrails'] = next_line if next_line && !next_line.match?(/Anganwadi/)
      
      # Anganwadi
      when "Anganwadi At Premises"
        data['facilities']['anganwadi']['at_premises'] = next_line if next_line
      when "Anganwadi Boys"
        data['facilities']['anganwadi']['boys'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Girls"
        data['facilities']['anganwadi']['girls'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Worker"
        data['facilities']['anganwadi']['worker'] = next_line if next_line
      
      # Infrastructure - Toilets
      when "Toilets"
        in_toilet_section = true
        current_section = 'toilets'
        
        # Look ahead for toilet data
        toilet_data = []
        (i+1..i+20).each do |j|
          break if j >= lines.length
          toilet_data << lines[j]
        end
        
        # Try to find the values
        total_idx = toilet_data.index { |l| l =~ /Total.*CWSN/ }
        if total_idx && total_idx + 2 < toilet_data.length
          boys = toilet_data[total_idx + 1]
          girls = toilet_data[total_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['toilets']['boys']['total'] = boys.to_i
            data['infrastructure']['toilets']['girls']['total'] = girls.to_i
          end
        end
        
        func_idx = toilet_data.index("Functional")
        if func_idx && func_idx + 2 < toilet_data.length
          boys = toilet_data[func_idx + 1]
          girls = toilet_data[func_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['toilets']['boys']['functional'] = boys.to_i
            data['infrastructure']['toilets']['girls']['functional'] = girls.to_i
          end
        end
        
        cwsn_idx = toilet_data.index { |l| l =~ /CWSN Friendly/ }
        if cwsn_idx && cwsn_idx + 2 < toilet_data.length
          boys = toilet_data[cwsn_idx + 1]
          girls = toilet_data[cwsn_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['toilets']['boys']['cwsn'] = boys.to_i
            data['infrastructure']['toilets']['girls']['cwsn'] = girls.to_i
          end
        end
        
        urinal_idx = toilet_data.index("Urinal")
        if urinal_idx && urinal_idx + 2 < toilet_data.length
          boys = toilet_data[urinal_idx + 1]
          girls = toilet_data[urinal_idx + 2]
          if boys =~ /^\d+$/ && girls =~ /^\d+$/
            data['infrastructure']['toilets']['boys']['urinals'] = boys.to_i
            data['infrastructure']['toilets']['girls']['urinals'] = girls.to_i
          end
        end
      
      # Basic Facilities
      when "Handwash Near Toilet"
        data['facilities']['basic']['sanitation']['handwash_near_toilet'] = next_line if next_line && !next_line.match?(/Handwash Facility/)
      when "Handwash Facility for Meal"
        data['facilities']['basic']['sanitation']['handwash_for_meal'] = next_line if next_line && !next_line.match?(/Total Class/)
      when "Drinking Water Available"
        data['facilities']['basic']['water']['available'] = next_line if next_line && !next_line.match?(/Drinking Water Fun/)
      when "Drinking Water Functional"
        data['facilities']['basic']['water']['functional'] = next_line if next_line && !next_line.match?(/Rain/)
      when "Rain Water Harvesting"
        data['facilities']['basic']['water']['rain_water_harvesting'] = next_line if next_line && !next_line.match?(/Playground/)
      when "Playground Available"
        data['facilities']['basic']['safety']['playground'] = next_line if next_line && !next_line.match?(/Furniture/)
      when "Electricity Availability"
        data['facilities']['basic']['electricity']['available'] = next_line if next_line && !next_line.match?(/Solar/)
      when "Solar Panel"
        data['facilities']['basic']['electricity']['solar_panel'] = next_line if next_line && !next_line.match?(/Medical/)
      when "Library Availability"
        data['infrastructure']['library']['available'] = next_line if next_line && !next_line.match?(/Separate/)
      when "Separate Room for HM"
        data['infrastructure']['other_facilities']['hm_room'] = next_line if next_line && !next_line.match?(/Drinking/)
      when "Furniture Availability"
        if next_line =~ /^\d+$/
          data['infrastructure']['furniture']['count'] = next_line.to_i
        end
      
      # Infrastructure - Classrooms
      when "Total Class Rooms"
        in_toilet_section = false
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['total'] = next_line.to_i
        end
      when "In Good Condition"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['good_condition'] = next_line.to_i
        end
      when "Needs Minor Repair"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['needs_minor_repair'] = next_line.to_i
        end
      when "Needs Major Repair"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['needs_major_repair'] = next_line.to_i
        end
      when "Other Rooms"
        if next_line =~ /^\d+$/
          data['infrastructure']['classrooms']['other_rooms'] = next_line.to_i
        end
      
      # Digital Facilities
      when "Digital Facilities (Functional)"
        in_digital_section = true
        in_toilet_section = false
      when "ICT Lab" && in_digital_section
        data['infrastructure']['digital_facilities']['ict_lab'] = next_line if next_line && !next_line.match?(/Internet/)
      when "Internet" && in_digital_section
        data['infrastructure']['digital_facilities']['internet'] = next_line if next_line && !next_line.match?(/Desktop/)
      when "Desktop" && in_digital_section
        data['infrastructure']['digital_facilities']['desktop'] = next_line.to_i if next_line =~ /^\d+$/
      when "Laptop" && in_digital_section
        data['infrastructure']['digital_facilities']['laptop'] = next_line.to_i if next_line =~ /^\d+$/
      when "Tablet" && in_digital_section
        data['infrastructure']['digital_facilities']['tablet'] = next_line.to_i if next_line =~ /^\d+$/
      when "Printer" && in_digital_section
        data['infrastructure']['digital_facilities']['printer'] = next_line.to_i if next_line =~ /^\d+$/
      when "Projector" && in_digital_section
        data['infrastructure']['digital_facilities']['projector'] = next_line.to_i if next_line =~ /^\d+$/
      when "DigiBoard" && in_digital_section
        data['infrastructure']['digital_facilities']['digiboard'] = next_line.to_i if next_line =~ /^\d+$/
      when "DTH" && in_digital_section
        data['infrastructure']['digital_facilities']['dth'] = next_line if next_line && !next_line.match?(/DigiBoard/)
      
      # Academic
      when "Medium of Instruction"
        in_digital_section = false
      when /^Medium (\d)$/
        medium_num = $1
        if next_line && next_line =~ /^(\d+)-(.+)$/
          code = $1
          name = $2.strip
          data['academic']['medium_of_instruction']["medium_#{medium_num}"] = {
            'code' => code,
            'name' => name
          }
        end
      
      # Academic Inspections
      when "Visit of school for / by"
      when "Acad. Inspections"
        data['academic']['inspections']['visits']['academic'] = next_line.to_i if next_line =~ /^\d+$/
      when "CRC Coordinator"
        data['academic']['inspections']['visits']['crc_coordinator'] = next_line.to_i if next_line =~ /^\d+$/
      when "Block Level Officers"
        data['academic']['inspections']['visits']['block_level'] = next_line.to_i if next_line =~ /^\d+$/
      when "State/District Officers"
        data['academic']['inspections']['visits']['state_district'] = next_line.to_i if next_line =~ /^\d+$/
      
      # Academic Hours and Days
      when "Instructional days"
        if next_line =~ /^\d+$/
          data['academic']['hours']['instructional']['days'] = next_line.to_i
        end
      when "Avg.School hrs.Std."
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['student_hours'] = next_line.to_f
        end
      when "Avg.School hrs.Tch."
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['hours']['instructional']['teacher_hours'] = next_line.to_f
        end
      when "CCE"
        data['academic']['assessments']['cce']['implemented'] = next_line if next_line && !next_line.match?(/Total/)
      
      # Teachers
      when "Teachers"
        in_teacher_section = true
        in_digital_section = false
      when "Regular" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['regular'] = next_line.to_i
        end
      when "Part-time" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['part_time'] = next_line.to_i
        end
      when "Contract" && in_teacher_section
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['contract'] = next_line.to_i
        end
      when "Male"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['male'] = next_line.to_i
        end
      when "Female"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['female'] = next_line.to_i
        end
      when "Transgender"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['transgender'] = next_line.to_i
        end
      
      # Teacher Assignments and Classes
      when "Total Teacher Involve in Non Teaching Assignment"
        if next_line =~ /^\d+$/
          data['teachers']['assignments']['non_teaching'] = next_line.to_i
        end
      when /^(\d+)-(\w+.*?)$/
        class_level = $1
        description = $2.strip
        if next_line =~ /^\d+$/
          data['teachers']['classes_taught'][class_level] = {
            'description' => description,
            'count' => next_line.to_i
          }
        end
      
      # Teacher Qualifications
      when "Below Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['below_graduate'] = next_line.to_i
        end
      when "Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['graduate'] = next_line.to_i
        end
      when "Post Graduate and Above"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['post_graduate_and_above'] = next_line.to_i
        end
      when "Diploma or Certificate in basic teachers training"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['basic_training'] = next_line.to_i
        end
      when "B.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['bed'] = next_line.to_i
        end
      when "M.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['med'] = next_line.to_i
        end
      when "Total Teacher Trained in Computer"
        if next_line =~ /^\d+$/
          data['teachers']['training']['computer_trained'] = next_line.to_i
        end
      when "Teachers Aged above 55"
        if next_line =~ /^\d+$/
          data['teachers']['age_distribution']['above_55'] = next_line.to_i
        end
      
      # Student Enrollment - RTE
      when "Total no. of Students Enrolled Under Section 12 of the RTE Act"
        current_section = 'rte'
      when /^Class ([IVX]+)$/ && current_section == 'rte'
        class_num = roman_to_arabic($1)
        if class_num && next_line =~ /^B\s+G$/
          boys = lines[i + 2]&.strip.to_i
          girls = lines[i + 3]&.strip.to_i
          data['students']['enrollment']['rte']['section_12']["class_#{class_num}"] = {
            'boys' => boys,
            'girls' => girls
          }
        end
      
      # Student Enrollment - EWS
      when "Total no. of Economically Weaker Section"
        current_section = 'ews'
      when /^Class ([IVX]+)$/ && current_section == 'ews'
        class_num = roman_to_arabic($1)
        if class_num && next_line =~ /^B\s+G$/
          boys = lines[i + 2]&.strip.to_i
          girls = lines[i + 3]&.strip.to_i
          data['students']['enrollment']['rte']['ews']["class_#{class_num}"] = {
            'boys' => boys,
            'girls' => girls
          }
        end
      
      # Residential Info
      when "Residential School"
        if next_line && next_line =~ /^(\d+)\s*-\s*(.+)$/
          code = $1
          type = $2.strip
          data['facilities']['residential']['details']['type'] = "#{code} - #{type}"
        end
      when "Residential Type"
        data['facilities']['residential']['details']['category'] = next_line if next_line && !next_line.match?(/Minority/)
      when "Minority School"
        data['facilities']['residential']['details']['minority_school'] = next_line if next_line && !next_line.match?(/Approachable/)
      when "Approachable By All Weather Road"
        data['facilities']['basic']['safety']['all_weather_road'] = next_line if next_line && !next_line.match?(/Toilets/)
      
      # Student Facilities
      when "Free text books"
        if next_line =~ /^\d+$/
          data['students']['facilities']['incentives']['free_textbooks'] = next_line.to_i
        end
      when "Transport"
        if next_line =~ /^\d+$/
          data['students']['facilities']['general']['transport'] = next_line.to_i
        end
      when "Free uniform"
        if next_line =~ /^\d+$/
          data['students']['facilities']['incentives']['free_uniform'] = next_line.to_i
        end
      
      # Committees
      when "SMC Exists"
        data['committees']['smc']['details']['exists'] = next_line if next_line && !next_line.match?(/SMC & SMDC/)
      when "SMC & SMDC Same"
        data['committees']['smc']['details']['same_as_smdc'] = next_line if next_line && !next_line.match?(/SMDC Con/)
      when "SMDC Constituted"
        data['committees']['smdc']['details']['constituted'] = next_line if next_line && !next_line.match?(/Text Books/)
      
      # Grants
      when "Grants Receipt"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['received']['composite']['amount'] = next_line.to_f
        end
      when "Grants Expenditure"
        if next_line =~ /^\d+\.?\d*$/
          data['grants']['expenditure']['composite']['amount'] = next_line.to_f
        end
      
      # Add new pattern matches
      when "Medical checkups"
        data['facilities']['medical']['checkups']['regular']['available'] = next_line if next_line
      when "First Aid Kit"
        data['facilities']['medical']['first_aid']['equipment']['available'] = next_line if next_line
      when "School Medical Officer"
        data['facilities']['medical']['staff']['doctor']['available'] = next_line if next_line
      
      # Library details
      when "Library Books"
        data['infrastructure']['library']['books']['total'] = next_line.to_i if next_line =~ /^\d+$/
      when "Library Type"
        data['infrastructure']['library']['details']['type'] = next_line if next_line
      when "Librarian"
        data['infrastructure']['library']['staff']['librarian'] = next_line if next_line
      
      # Teacher training
      when "No. of Total Teacher Received Service Training"
        data['teachers']['training']['service']['total'] = next_line.to_i if next_line =~ /^\d+$/
      when "Special Training Received"
        data['teachers']['training']['special']['received'] = next_line if next_line
      
      # Student performance
      when /Pass % Class (\d+)/
        class_num = $1
        if next_line =~ /^\d+\.?\d*$/
          data['academic']['assessments']['board_results']["class_#{class_num}"]['pass_percentage'] = next_line.to_f
        end
      
      # Sports facilities
      when "Sports Equipment"
        data['academic']['sports']['equipment']['available'] = next_line if next_line
      when "Physical Education Teacher"
        data['academic']['sports']['instructors']['available'] = next_line if next_line
      
      # Safety measures
      when "Fire Extinguisher"
        data['facilities']['safety']['fire']['equipment']['extinguisher'] = next_line if next_line
      when "Emergency Exit"
        data['facilities']['safety']['emergency']['exits']['available'] = next_line if next_line
      when "Security Guard"
        data['facilities']['safety']['security']['personnel']['guard'] = next_line if next_line
      
      # Committee meetings
      when "SMC Meetings Conducted"
        data['committees']['smc']['details']['meetings']['count'] = next_line.to_i if next_line =~ /^\d+$/
      when "SMDC Meetings Conducted"
        data['committees']['smdc']['details']['meetings']['count'] = next_line.to_i if next_line =~ /^\d+$/
      
      # Vocational courses
      when "Vocational Courses"
        data['academic']['vocational']['courses']['available'] = next_line if next_line
      when "Vocational Trainer"
        data['academic']['vocational']['trainers']['available'] = next_line if next_line
      
      # Student social categories
      when /^([A-Z]+)\s+Boys\s+(\d+)\s+Girls\s+(\d+)$/
        category = $1.downcase
        boys = $2.to_i
        girls = $3.to_i
        if ['sc', 'st', 'obc', 'general'].include?(category)
          data['students']['enrollment']['by_social_category'][category] = {
            'boys' => boys,
            'girls' => girls
          }
        end
      
      # CWSN details
      when "CWSN Facilities"
        data['students']['enrollment']['cwsn']['facilities']['available'] = next_line if next_line
      when /CWSN Type:\s+(.+)/
        type = $1
        if next_line =~ /Boys\s+(\d+)\s+Girls\s+(\d+)/
          data['students']['enrollment']['cwsn']['by_type'][type.downcase] = {
            'boys' => $1.to_i,
            'girls' => $2.to_i
          }
        end
      
      # Teacher workload
      when /Teaching Hours per Week/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['teaching_hours']['per_week'] = $1.to_i
        end
      when /Non-Teaching Hours/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['non_teaching_hours']['per_week'] = $1.to_i
        end
      
      # Teacher subject-wise allocation
      when /^Subject:\s*(.+?)(?:\s*,\s*Teachers:\s*(\d+))?$/
        subject = $1.strip
        count = $2&.to_i || 0
        data['teachers']['workload']['by_subject'][subject.downcase] = count
      
      # Student attendance
      when /Monthly Attendance/
        current_section = 'attendance'
      when /^(\w+)\s+(\d+\.?\d*)%$/ && current_section == 'attendance'
        month = $1.downcase
        percentage = $2.to_f
        data['students']['attendance']['monthly'][month] = percentage
      
      # Language subjects
      when /^Language (\d+):\s*(.+)$/
        num = $1
        lang = $2.strip
        data['academic']['subjects']['languages']['details']["language_#{num}"] = lang
      
      # Core subjects
      when /^Core Subject (\d+):\s*(.+)$/
        num = $1
        subject = $2.strip
        data['academic']['subjects']['core']['details']["subject_#{num}"] = subject
      
      # Elective subjects
      when /^Elective (\d+):\s*(.+)$/
        num = $1
        subject = $2.strip
        data['academic']['subjects']['electives']['details']["elective_#{num}"] = subject
      
      # Classroom usage
      when /^Room (\d+) Usage:\s*(.+)$/
        room = $1
        usage = $2.strip
        data['infrastructure']['classrooms']['usage']['regular']["room_#{room}"] = usage
      
      # Lab details
      when /^Lab Type:\s*(.+?)(?:\s*,\s*Capacity:\s*(\d+))?$/
        type = $1.strip
        capacity = $2&.to_i
        data['infrastructure']['classrooms']['usage']['labs'][type.downcase] = {
          'capacity' => capacity
        }
      
      # Special room details
      when /^Special Room:\s*(.+?)(?:\s*,\s*Purpose:\s*(.+))?$/
        room = $1.strip
        purpose = $2&.strip
        data['infrastructure']['classrooms']['usage']['special_rooms'][room.downcase] = {
          'purpose' => purpose
        }
      
      # Student performance details
      when /^Class (\d+) Performance$/
        current_class = $1
        in_performance_section = true
      when /^(\w+)\s+(\d+\.?\d*)%$/ && in_performance_section
        subject = $1.strip.downcase
        percentage = $2.to_f
        data['students']['performance']['by_class']["class_#{current_class}"] ||= {}
        data['students']['performance']['by_class']["class_#{current_class}"][subject] = percentage
      
      # Committee details
      when /^Committee:\s*(.+?)(?:\s*,\s*Members:\s*(\d+))?$/
        committee = $1.strip.downcase
        members = $2&.to_i
        data['committees'][committee] ||= {}
        data['committees'][committee]['members'] = members if members
      
      # Safety measures
      when /^Safety Measure:\s*(.+?)(?:\s*,\s*Status:\s*(.+))?$/
        measure = $1.strip.downcase
        status = $2&.strip
        data['facilities']['safety']['measures'] ||= {}
        data['facilities']['safety']['measures'][measure] = status
      
      # Medical facilities
      when /^Medical Facility:\s*(.+?)(?:\s*,\s*Availability:\s*(.+))?$/
        facility = $1.strip.downcase
        availability = $2&.strip
        data['facilities']['medical']['facilities'] ||= {}
        data['facilities']['medical']['facilities'][facility] = availability
      
      # Sports facilities
      when /^Sport:\s*(.+?)(?:\s*,\s*Equipment:\s*(\d+))?$/
        sport = $1.strip.downcase
        equipment = $2&.to_i
        data['academic']['sports']['facilities'][sport] = {
          'equipment_count' => equipment
        }
      
      # Library resources
      when /^Book Category:\s*(.+?)(?:\s*,\s*Count:\s*(\d+))?$/
        category = $1.strip.downcase
        count = $2&.to_i
        data['infrastructure']['library']['books']['by_category'] ||= {}
        data['infrastructure']['library']['books']['by_category'][category] = count
      
      # Grant utilization
      when /^Grant Type:\s*(.+?)(?:\s*,\s*Utilization:\s*(\d+\.?\d*)%)?$/
        type = $1.strip.downcase
        utilization = $2&.to_f
        data['grants']['utilization']['by_type'] ||= {}
        data['grants']['utilization']['by_type'][type] = utilization
      end
    end

    # Clean up empty sections
    data.each do |_, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data.reject! { |_, v| v.empty? }
    
    data
  end

  private

  def self.roman_to_arabic(roman)
    roman_values = {
      'I' => 1,
      'V' => 5,
      'X' => 10,
      'L' => 50,
      'C' => 100,
      'D' => 500,
      'M' => 1000
    }
    
    result = 0
    prev_value = 0
    
    roman.reverse.each_char do |char|
      curr_value = roman_values[char]
      if curr_value >= prev_value
        result += curr_value
      else
        result -= curr_value
      end
      prev_value = curr_value
    end
    
    result
  end
end