trigger Account_After_Update on Account (after update) {
    Map<Id, Id> accountOldOwnerId = new Map<Id, Id>();
    List<Task> updateTask = new List<Task>();

    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Account a : Trigger.new) {
            String oldOwnerId = Trigger.oldMap.get(a.Id).OwnerId;
            String newOwnerId = a.OwnerId;

            if (oldOwnerId != newOwnerId) {
                accountOldOwnerId.put(a.Id, oldOwnerId);
            }
        }

        Map<Id, User> oldOwners = new Map<Id, User>([
            SELECT u.Id, u.IsActive 
            FROM User u 
            WHERE u.Id IN :accountOldOwnerId.values() 
            AND u.IsActive = true
        ]);

        List<Account> accs = [
            SELECT OwnerId, (SELECT OwnerId FROM Tasks) 
            FROM Account 
            WHERE Id IN :accountOldOwnerId.keySet()
        ];

        for (Account acc : accs) {
            Id oldOwnerId = accountOldOwnerId.get(acc.Id);
            if (oldOwners.containsKey(oldOwnerId)) {
                for (Task tsk : acc.Tasks) {
                    tsk.OwnerId = oldOwnerId;
                    updateTask.add(tsk);
                }
            }
        }

        if (!updateTask.isEmpty()) {
            update updateTask;
        }
    }
}