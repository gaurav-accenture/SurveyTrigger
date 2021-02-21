trigger SurveyTrigger on Survey_Request__c (after insert, after update) {
    List<Survey_Request__c> SRList = new List<Survey_Request__c>();

    Boolean isRecordPresent = true;
    for(Survey_Request__c sr: trigger.new){
        isRecordPresent = true;
        if(trigger.oldMap == null){
            // oldMap is absent
            isRecordPresent = false;
        } else if(!trigger.oldMap.keySet().contains(sr.id)){
            //oldmap not empty but record not present
            isRecordPresent = false;
        }

        if(!isRecordPresent){
            //isRecordPresent = false record not present in trigger.old
            if(sr.Status__c == 'Stop'){
                sr.adderror('Error! Survey Requests status cant be stop at the time of creation');
            }else{
                if(sr.Stop_Started_Date__c == null){
                    Survey_Request__c cloneRecord = sr.clone(true, true, false, false);
                    SRList.add(cloneRecord);
                    // SRList.add(sr);
                }else{
                    sr.adderror('Error! For status other than "Stop" Stopdate must be empty');
                }
            }
        } else{
           // sr is being updated
            Survey_Request__c oldRecord = trigger.oldMap.get(sr.id);

            if(oldRecord.Status__c == 'Close' && sr.Status__c!='Close'){
                // cant update status once its set to close
                sr.adderror('Error! Survey Request Status cant be updated once status is closed.');

            }else if(sr.Status__c == 'Stop')
            {
                if(sr.Stop_Started_Date__c != null && sr.Stop_Started_Date__c <= System.today())
                {
                    if(oldRecord.Stop_Started_Date__c != sr.Stop_Started_Date__c)
                    {
                        Survey_Request__c cloneRecord = sr.clone(true, true, false, false);
                        cloneRecord.Total_Stop_Duration_in_Days__c = cloneRecord.Stop_Started_Date__c.daysBetween(System.today());
                        SRList.add(cloneRecord);
                    }
                }else
                {
                    if(sr.Stop_Started_Date__c == null){
                        sr.adderror('Error! Please provide stop started date');
                    }else if(sr.Stop_Started_Date__c > System.today()){
                        sr.adderror('Error! Stop started cant be in future');
                    }
                }
            }else if(oldRecord.Status__c != sr.Status__c && sr.Status__c != 'Stop'){
                // status changed from stop to else
                if(sr.Stop_Started_Date__c != null){
                    sr.adderror('Error! Stop Started date must be empty for other status');
                }else{
                    Survey_Request__c cloneRecord = sr.clone(true, true, false, false);
                    cloneRecord.Total_Stop_Duration_in_Days__c = null;
                    SRList.add(cloneRecord);
                }
            } 
        }
    }

    if(!SRList.isEmpty()){
        update SRList;
    } 
}