/**
 * @description Base trigger handler with recursion prevention
 * @author Sai Chaganti
 */
public virtual class TriggerHandler {
    
    private static Map<String, Integer> executionCountMap = new Map<String, Integer>();
    private static final Integer MAX_EXECUTION_COUNT = 1;
    
    protected Boolean isTriggerExecuting;
    protected Integer batchSize;
    protected List<SObject> newRecords;
    protected List<SObject> oldRecords;
    protected Map<Id, SObject> newRecordsMap;
    protected Map<Id, SObject> oldRecordsMap;
    
    public TriggerHandler() {
        this.isTriggerExecuting = Trigger.isExecuting;
        this.batchSize = (Trigger.new != null) ? Trigger.new.size() : 0;
        this.newRecords = Trigger.new;
        this.oldRecords = Trigger.old;
        this.newRecordsMap = Trigger.newMap;
        this.oldRecordsMap = Trigger.oldMap;
    }
    
    public void execute() {
        if (!isTriggerExecuting) {
            return;
        }
        
        if (hasExceededMaxExecutions()) {
            return;
        }
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert();
            } else if (Trigger.isUpdate) {
                beforeUpdate();
            } else if (Trigger.isDelete) {
                beforeDelete();
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert();
            } else if (Trigger.isUpdate) {
                afterUpdate();
            } else if (Trigger.isDelete) {
                afterDelete();
            } else if (Trigger.isUndelete) {
                afterUndelete();
            }
        }
    }
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeInsert() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeUpdate() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void beforeDelete() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterInsert() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterUpdate() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterDelete() {}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void afterUndelete() {}
    
    private Boolean hasExceededMaxExecutions() {
        String handlerName = getHandlerName();
        Integer executionCount = executionCountMap.get(handlerName) ?? 0;
        executionCount++;
        executionCountMap.put(handlerName, executionCount);
        return executionCount > MAX_EXECUTION_COUNT;
    }
    
    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }
    
    public static void bypass(String handlerName) {
        executionCountMap.put(handlerName, MAX_EXECUTION_COUNT + 1);
    }
    
    public static void clearBypass(String handlerName) {
        executionCountMap.remove(handlerName);
    }
    
    public static Boolean isBypassed(String handlerName) {
        return executionCountMap.containsKey(handlerName) && 
               executionCountMap.get(handlerName) > MAX_EXECUTION_COUNT;
    }
}
