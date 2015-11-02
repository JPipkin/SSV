global class ValidateAddresses_AccountBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    global Integer numSuccess = 0;
    global String dmlFailures = null;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        try
        {
            String query = 'Select Id, BillingCity,BillingStreet,BillingState,BillingPostalCode '+
                'from Account where BillingStreet != null and BillingCity != null and BillingPostalCode != null and SmartyStreets1__BillingVerified__c = false';

            if(Test.isRunningTest())
                query += ' limit 70';

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
            SmartyValidation.SmartyStreetsAPIUtils util = new SmartyValidation.SmartyStreetsAPIUtils();

            Map<Integer,SmartyValidation.SmartyValidationRecord> ssRecords = new Map<Integer,SmartyValidation.SmartyValidationRecord>();
            ssRecords.putAll(util.setValidationRecords(alist));
            String payload = JSON.serialize(ssRecords.values());
            Map<Integer,SmartyValidation.SmartyValidationReturn> svMap = new Map<Integer,SmartyValidation.SmartyValidationReturn>();
            svMap.putAll(util.smartyStreetsCallout(payload,true));

            List<Account> updAList = new List<Account>();
            for(Integer r :ssRecords.keySet()){
                SmartyValidation.SmartyValidationRecord svr = ssRecords.get(r);
                SmartyValidation.SmartyValidationReturn svret = svMap.get(r);
                Account a = new Account(Id=svr.RecordId);

                if(svret==null){
                    continue;
                }

                SmartyValidation.ValidatedAddress address = new SmartyValidation.ValidatedAddress(svret);
                Map<String,String> fmap = new Map<String,String>{
                    'street'=>'BillingStreet',
                    'city'=>'BillingCity',
                    'state'=>'BillingState',
                    'zip'=>'BillingZip',
                    'verified_date'=>'SmartyStreets1__BillingVerDate__c',
                    'verified_box'=>'SmartyStreets1__BillingVerified__c',
                    'normalized'=>'SmartyNormalized__c'
                };
                SObject so = SmartyValidation.doVerifiedUpdates((Sobject)a, fmap,address);
                if(so==null){
                    continue;
                }
                a = (Account)so;
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
            System.debug(ex);
        }
    }
        
    global void finish(Database.BatchableContext bc) {}
    
}