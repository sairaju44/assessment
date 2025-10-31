/**
 * @description Test class for TriggerHandler
 * @author Sai Chaganti
 */
@IsTest
private class TriggerHandlerTest {
    
    @IsTest
    static void testHandlerBypass() {
        String handlerName = 'TestHandler';
        
        Test.startTest();
        TriggerHandler.bypass(handlerName);
        System.assert(TriggerHandler.isBypassed(handlerName), 'Handler should be bypassed');
        
        TriggerHandler.clearBypass(handlerName);
        System.assert(!TriggerHandler.isBypassed(handlerName), 'Handler should not be bypassed');
        Test.stopTest();
    }
    
    @IsTest
    static void testMultipleBypass() {
        String handler1 = 'TestHandler1';
        String handler2 = 'TestHandler2';
        
        Test.startTest();
        TriggerHandler.bypass(handler1);
        TriggerHandler.bypass(handler2);
        
        System.assert(TriggerHandler.isBypassed(handler1), 'Handler1 should be bypassed');
        System.assert(TriggerHandler.isBypassed(handler2), 'Handler2 should be bypassed');
        
        TriggerHandler.clearBypass(handler1);
        
        System.assert(!TriggerHandler.isBypassed(handler1), 'Handler1 should not be bypassed');
        System.assert(TriggerHandler.isBypassed(handler2), 'Handler2 should still be bypassed');
        Test.stopTest();
    }
}
