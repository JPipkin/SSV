public class SmartyValidation {

    public static String auth_id = SmartyStreets1__Settings__c.getOrgDefaults().SmartyStreets1__Auth_ID__c;
    public static String auth_token = SmartyStreets1__Settings__c.getOrgDefaults().SmartyStreets1__Auth_Token__c;


    public class SmartyValidationReturn{
        public Integer input_index;
        public Integer candidate_index;
        public String first_line;
        public String last_line;
        public String delivery_point_barcode;
        public String delivery_line_1;
        public ResComponents components;
        public ResMetadata metadata;
        public ResAnalysis analysis;
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
        public String normalized {get;private set;}
        public SmartyValidation.ResComponents c;

        public ValidatedAddress(SmartyValidation.SmartyValidationReturn ret){
            this.c = ret.components;
            if(c != null){
                buildAddress();
                normalize();
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
        private void normalize(){
            normalized = nullCheck(c.primary_number) + '|' + nullCheck(c.street_name) + ' ' + nullCheck(c.street_suffix);
            normalized += '|' + nullCheck(c.secondary_number);
            normalized += '|' + nullCheck(c.state_abbreviation) + '|' + nullCheck(c.zipcode) + '|' + nullCheck(c.plus4_code);
        }
        private String nullCheck(String n){
            return (n==null?'':n);
        }

        public Boolean checkIfValid(){
            return (c.primary_number != null && c.street_name != null && c.street_suffix != null && city != null && state != null && zip != null);
        }
    }

    public static SObject doVerifiedUpdates(SObject obj, Map<String,String> fieldMaping,SmartyValidation.ValidatedAddress address){
        Boolean minimumMappingPresent = false;
        minimumMappingPresent = (fieldMaping.containsKey('street') && fieldMaping.containsKey('city') &&
            fieldMaping.containsKey('state') && fieldMaping.containsKey('zip') && fieldMaping.containsKey('verified_date') &&
            fieldMaping.containsKey('verified_box'));
        system.debug(LoggingLevel.ERROR, 'pipkin~~~~ fieldMapping:\n' + JSON.serializePretty(fieldMaping));
        system.debug(LoggingLevel.ERROR, 'pipkin~~~~ minimumMappingPresent: ' + minimumMappingPresent);
        if(!minimumMappingPresent)return null;
        for(String s :fieldMaping.get('street').split(';')){
            obj.put(s,address.street);
        }
        for(String s :fieldMaping.get('city').split(';')){
            obj.put(s,address.city);
        }
        for(String s :fieldMaping.get('state').split(';')){
            obj.put(s,address.city);
        }
        for(String s :fieldMaping.get('zip').split(';')){
            obj.put(s,address.city);
        }
        obj.put(fieldMaping.get('verified_date'),system.today().format());
        obj.put(fieldMaping.get('verified_box'),true);
        if(fieldMaping.containsKey('normalized')){
            obj.put(fieldMaping.get('normalized'),address.normalized);
        }
        if(fieldMaping.containsKey('invalid_search')){
            obj.put(fieldMaping.get('invalid_search'),false);
        }
        return obj;
    }

    public class SmartyStreetsAPIUtils {
        
        public SmartyStreetsAPIUtils(){}

        public Map<Integer,SmartyValidation.SmartyValidationRecord> setValidationRecords(List<Account> objList){
            Map<Integer,SmartyValidation.SmartyValidationRecord> ssRecords = new Map<Integer,SmartyValidation.SmartyValidationRecord>();
            Integer ind = 0;
            for(Account o :objList){
                SmartyValidation.SmartyValidationRecord r = new SmartyValidation.SmartyValidationRecord();
                r.street = o.BillingStreet;
                r.city = o.BillingCity;
                r.state = o.BillingState;
                r.zipcode = o.BillingPostalCode;
                r.recordId = o.Id;
                ssRecords.put(ind,r);
                ind++;
            }
            return ssRecords;
        }

        public Map<Integer,SmartyValidation.SmartyValidationRecord> setValidationRecords(List<Lead> objList){
            Map<Integer,SmartyValidation.SmartyValidationRecord> ssRecords = new Map<Integer,SmartyValidation.SmartyValidationRecord>();
            Integer ind = 0;
            for(Lead o :objList){
                SmartyValidation.SmartyValidationRecord r = new SmartyValidation.SmartyValidationRecord();
                r.street = o.Street;
                r.city = o.City;
                r.state = o.State;
                r.zipcode = o.PostalCode;
                r.recordId = o.Id;
                ssRecords.put(ind,r);
                ind++;
            }
            return ssRecords;
        }

        public Map<Integer,SmartyValidation.SmartyValidationRecord> setValidationRecords(List<Contact> objList){
            Map<Integer,SmartyValidation.SmartyValidationRecord> ssRecords = new Map<Integer,SmartyValidation.SmartyValidationRecord>();
            Integer ind = 0;
            for(Contact o :objList){
                SmartyValidation.SmartyValidationRecord r = new SmartyValidation.SmartyValidationRecord();
                r.street = o.MailingStreet;
                r.city = o.MailingCity;
                r.state = o.MailingState;
                r.zipcode = o.MailingPostalCode;
                r.recordId = o.Id;
                ssRecords.put(ind,r);
                ind++;
            }
            return ssRecords;
        }

        public Map<Integer,SmartyValidation.SmartyValidationReturn> smartyStreetsCallout(String payload, Boolean includeOnlyValid){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            String ep = 'https://api.smartystreets.com/street-address?auth-id='+auth_id+'&auth-token=' + auth_token;
            req.setBody(payload);
            req.setEndpoint(ep);
            if(!includeOnlyValid)
                req.setHeader('X-Include-Invalid','true');
            req.setMethod('POST');

            HTTPResponse res = h.send(req);
            String records =res.getBody();
            //system.debug('response records: ' + records);

            JSONParser parser = JSON.createParser(records);
            Map<Integer,SmartyValidation.SmartyValidationReturn> svMap = new Map<Integer,SmartyValidation.SmartyValidationReturn>();
            while(parser.nextToken() != null){
                system.debug(parser.getCurrentToken());
                if(parser.getCurrentToken() == JSONToken.START_OBJECT){
                    SmartyValidation.SmartyValidationReturn sv = (SmartyValidation.SmartyValidationReturn)parser.readValueAs(SmartyValidation.SmartyValidationReturn.class);
                    // system.debug('pipkin ' + JSON.serializePretty(sv));
                    svMap.put(sv.input_index,sv);
                }
            }
            system.debug(LoggingLevel.ERROR,'pipkin~~~~ svMap =\n' + JSON.serializePretty(svMap));
            return svMap;
        }
    }
}