global class ValidateAddresses_AccountBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    global Integer numSuccess = 0;
    global String dmlFailures = null;
    global static String auth_id = SmartyStreets1__Settings__c.getOrgDefaults().SmartyStreets1__Auth_ID__c;
    global static String auth_token = SmartyStreets1__Settings__c.getOrgDefaults().SmartyStreets1__Auth_Token__c;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        try
        {
            String query = 'Select Id, BillingCity,BillingStreet,BillingState,BillingPostalCode '+
                'from Account where BillingStreet != null and BillingCity != null and BillingPostalCode != null and SmartyStreets1__BillingVerified__c = false';

            if(Test.isRunningTest())
                query += ' limit 70'; //Do not set higher than schedulable class executeBatch size or will fail test

            return Database.getQueryLocator(query);
        }
        catch(Exception ex)
        {
            return Database.getQueryLocator('Select Id from Account where Id = null');
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Account> alist){

        try
        {
            Map<Integer,SmartyValidation.SmartyValidationRecord> ssRecords = new Map<Integer,SmartyValidation.SmartyValidationRecord>();
            Integer ind = 0;
            for(Account a :alist){
                SmartyValidation.SmartyValidationRecord r = new SmartyValidation.SmartyValidationRecord();
                r.street = a.BillingStreet;
                r.city = a.BillingCity;
                r.state = a.BillingState;
                r.zipcode = a.BillingPostalCode;
                r.recordId = a.Id;
                ssRecords.put(ind,r);
                ind++;
            }
            String payload = JSON.serialize(ssRecords.values());

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            String ep = 'https://api.smartystreets.com/street-address?auth-id='+auth_id+'&auth-token=' + auth_token;
            req.setBody(payload);
            req.setEndpoint(ep);
            req.setMethod('POST');

            HTTPResponse res = h.send(req);
            String records =res.getBody();
            //system.debug('response records: ' + records);

            JSONParser parser = JSON.createParser(records);
            Map<Integer,SmartyValidation.SmartyValidationReturn> svMap = new Map<Integer,SmartyValidation.SmartyValidationReturn>();
            while(parser.nextToken() != null){
                if(parser.getCurrentToken() == JSONToken.START_OBJECT){
                    SmartyValidation.SmartyValidationReturn sv = (SmartyValidation.SmartyValidationReturn)parser.readValueAs(SmartyValidation.SmartyValidationReturn.class);
                    // system.debug('pipkin ' + JSON.serializePretty(sv));
                    svMap.put(sv.input_index,sv);
                }
            }

            List<Account> updAList = new List<Account>();
            for(Integer r :ssRecords.keySet()){
                SmartyValidation.SmartyValidationRecord svr = ssRecords.get(r);
                SmartyValidation.SmartyValidationReturn svret = svMap.get(r);

                //system.debug('account: \n' + JSON.serializePretty(a));
                //system.debug('svrecord: \n' + JSON.serializePretty(svr));
                //system.debug('svreturn: \n' + JSON.serializePretty(svret));
                if(svret==null)continue;

                Account a = new Account(Id=svr.RecordId);
                SmartyValidation.ValidatedAddress address = new SmartyValidation.ValidatedAddress(svret);
                a.BillingStreet = address.street;
                a.BillingCity = address.city;
                a.BillingState = address.state;
                a.BillingPostalCode = address.zip;
                a.SmartyStreets1__BillingVerified__c = true;
                a.SmartyStreets1__BillingVerDate__c = system.today().format();
                system.debug(JSON.serializePretty(a));
                updAList.add(a);
            }
            
            Integer i = 0;
            Database.SaveResult[] srList = database.update(updAList, false) ;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) 
                    numSuccess++;
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        
                        String errMsg = 'Error updating Object (' + updAList[i].Id + '): ' + err.getStatusCode() + ': ' + err.getMessage() + ', ' +
                                                    'fields that affected this error: ' + err.getFields();
                        dmlFailures += '\n' + errMsg;
                        
                    }
                }// some failures
                i++;
            }
        }
        catch(Exception ex)
        {
            system.debug(ex);
        }


    }
        
    global void finish(Database.BatchableContext bc) {

    }
    
}