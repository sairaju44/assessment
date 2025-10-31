/**
 * @description Account trigger
 * @author Sai Chaganti
 */
trigger AccountTrigger on Account (before insert, before update, before delete, 
                                   after insert, after update, after delete, after undelete) {
    new AccountTriggerHandler().execute();
}

