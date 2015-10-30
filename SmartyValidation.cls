public class SmartyValidation {

    public class SmartyValidationReturn{
        public Integer input_index;
        public Integer candidate_index;
        public String first_line;
        public String last_line;
        public String delivery_point_barcode;
        public String delivery_line_1;
        public resComponents components;
        public resMetadata metadata;
        public resAnalysis analysis;
    }
     
    public class SmartyValidationRecord{
        public String recordId {get;set;}
        public String street {get;set;}
        public String state {get;set;}
        public String city {get;set;}
        public String zipcode {get;set;}
        public Integer candidates {get;set;}
        
        public SmartyValidationRecord(){
            this.candidates = 1;            
        }
    }

	public class ResComponents{
		public String primary_number;
        public String street_name;
        public String street_suffix;
        public String city_name;
        public String state_abbreviation;
        public String zipcode;
        public String plus4_code;
        public String delivery_point;
        public String delivery_point_check_digit;
        public String secondary_designator;
        public String secondary_number;
	}

	public class ResMetadata{
		public String record_type;
        public String zip_type;
        public String county_fips;
        public String county_name;
        public String carrier_route;
        public String congressional_district;
        public String building_default_indicator;
        public String rdi;
        public String elot_sequence;
        public String elot_sort;
        public Double latitude;
        public Double longitude;
        public String precision;
	}

	public class ResAnalysis{
		public String dpv_match_code;
        public String dpv_footnotes;
        public String dpv_cmra;
        public String dpv_vacant;
        public String active;
        public String footnotes;
	}

	public class ValidatedAddress{
		public String street {get;private set;}
		public String state {get;private set;}
		public String city {get;private set;}
		public String zip {get;private set;}
		public SmartyValidation.ResComponents c;

		public ValidatedAddress(SmartyValidation.SmartyValidationReturn ret){
			this.c = ret.components;
			if(c != null){
				buildAddress();
			}
		}
		private void buildAddress(){
			street = nullCheck(c.primary_number) + ' ' + nullCheck(c.street_name) + ' ' + nullCheck(c.street_suffix);
			if(c.secondary_designator != null){
				street += ' ' + c.secondary_designator;
			}
			if(c.secondary_number != null){
				street += ' ' + c.secondary_number;
			}
			city = c.city_name;
			state = c.state_abbreviation;
			zip = c.zipcode;
			if(c.plus4_code != null){
				zip += '-' + c.plus4_code;
			}
		}
		private String nullCheck(String n){
			return (n==null?'':n);
		}
	}
}