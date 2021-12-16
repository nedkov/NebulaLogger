//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest
private class LoggerSettingsController_Tests {
    private static final String CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME = 'CanModifyLoggerSettings';

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_custom_permission_is_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        insert testUser;
        PermissionSet permissionSet = new PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
        insert permissionSet;
        SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
            ParentId = permissionSet.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME]
            .Id
        );
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permissionSet.Id);
        insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };

        System.runAs(testUser) {
            System.assertEquals(true, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME), permissionSetAssignment);
            System.assertEquals(true, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_loggerAdmin_permission_set_is_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        insert testUser;
        LoggerTestUtils.assignAdminPermissionSet(testUser.Id);

        System.runAs(testUser) {
            System.assertEquals(true, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(true, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogViewer_permission_set_is_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        insert testUser;
        LoggerTestUtils.assignLogViewerPermissionSet(testUser.Id);

        System.runAs(testUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerEndUser_permission_set_is_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        insert testUser;
        LoggerTestUtils.assignEndUserPermissionSet(testUser.Id);

        System.runAs(testUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogCreator_permission_set_is_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        insert testUser;
        LoggerTestUtils.assignLogCreatorPermissionSet(testUser.Id);

        System.runAs(testUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_custom_permission_is_not_assigned() {
        User testUser = LoggerTestUtils.createStandardUser();
        System.runAs(testUser) {
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_return_loggingLevel_picklist_options() {
        Integer expectedLoggingLevelSize = LoggingLevel.values().size() - 1; // LoggingLEVEL.NONE and LoggingLevel.INTERNAL are ignored, '--NONE--' is automatically included
        List<LoggerSettingsController.PicklistOption> picklistOptions = LoggerSettingsController.getPicklistOptions().loggingLevelOptions;
        System.assertEquals(expectedLoggingLevelSize, picklistOptions.size());
        for (LoggerSettingsController.PicklistOption picklistOption : picklistOptions) {
            if (String.isBlank(picklistOption.value) == true) {
                System.assertEquals('--None--', picklistOption.label);
            } else {
                System.assertEquals(picklistOption.value, picklistOption.label);
                LoggingLevel matchingLoggingLevel = LoggingLevel.valueOf(picklistOption.value);
                System.assertEquals(matchingLoggingLevel.name(), picklistOption.label);
            }
        }
    }

    @IsTest
    static void it_should_return_loggerSaveMethod_picklist_options() {
        Integer expectedLoggerSaveMethodSize = Logger.SaveMethod.values().size() + 1; // '--NONE--' is automatically included
        List<LoggerSettingsController.PicklistOption> picklistOptions = LoggerSettingsController.getPicklistOptions().saveMethodOptions;
        System.assertEquals(expectedLoggerSaveMethodSize, picklistOptions.size());
        for (LoggerSettingsController.PicklistOption picklistOption : picklistOptions) {
            if (String.isBlank(picklistOption.value) == true) {
                System.assertEquals('--None--', picklistOption.label);
            } else {
                System.assertEquals(picklistOption.value, picklistOption.label);
                Logger.SaveMethod matchingLoggerSaveMethod = Logger.SaveMethod.valueOf(picklistOption.value);
                System.assertEquals(matchingLoggerSaveMethod.name(), picklistOption.label);
            }
        }
    }

    @IsTest
    static void it_should_return_setupOwnerType_picklist_options() {
        Set<String> expectedSetupOwnerType = new Set<String>{ 'Organization', 'Profile', 'User' };
        Integer expectedSetupOwnerTypeSize = 4; // Options are org, profile, and user, and '--NONE--' is automatically included
        List<LoggerSettingsController.PicklistOption> picklistOptions = LoggerSettingsController.getPicklistOptions().setupOwnerTypeOptions;
        System.assertEquals(expectedSetupOwnerTypeSize, picklistOptions.size());
        for (LoggerSettingsController.PicklistOption picklistOption : picklistOptions) {
            if (String.isBlank(picklistOption.value) == true) {
                System.assertEquals('--None--', picklistOption.label);
            } else {
                System.assertEquals(picklistOption.value, picklistOption.label);
                System.assertEquals(true, expectedSetupOwnerType.contains(picklistOption.value));
            }
        }
    }

    @IsTest
    static void it_should_return_shareAccessLevel_picklist_options() {
        Set<String> expectedShareAccessLevels = new Set<String>();
        for (Schema.PicklistEntry picklistEntry : Schema.Log__Share.AccessLevel.getDescribe().getPicklistValues()) {
            // The 'All' access level is an internal value and can't be granted
            if (picklistEntry.value != 'All') {
                expectedShareAccessLevels.add(picklistEntry.value);
            }
        }
        Integer expectedShareAccessLevelSize = expectedShareAccessLevels.size() + 1; // 'All' value is ignored, and '--NONE--' is automatically included
        List<LoggerSettingsController.PicklistOption> picklistOptions = LoggerSettingsController.getPicklistOptions().shareAccessLevelOptions;
        System.assertEquals(expectedShareAccessLevelSize, picklistOptions.size(), picklistOptions);
        for (LoggerSettingsController.PicklistOption picklistOption : picklistOptions) {
            if (String.isBlank(picklistOption.value) == true) {
                System.assertEquals('--None--', picklistOption.label);
            } else {
                System.assertEquals(picklistOption.value, picklistOption.label);
                System.assertEquals(true, expectedShareAccessLevels.contains(picklistOption.value));
            }
        }
    }

    @IsTest
    static void it_should_return_empty_settings_records_list_when_not_configured() {
        System.assertEquals(0, [SELECT COUNT() FROM LoggerSettings__c]);
        List<LoggerSettingsController.SettingsRecordResult> records = LoggerSettingsController.getRecords();
        System.assertEquals(0, records.size());
    }

    @IsTest
    static void it_should_return_settings_records_when_configured() {
        System.assertEquals(0, [SELECT COUNT() FROM LoggerSettings__c]);
        LoggerSettings__c orgDefaultSettingsRecord = LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c profileSettingsRecord = LoggerSettings__c.getInstance(UserInfo.getProfileId());
        LoggerSettings__c userSettingsRecord = LoggerSettings__c.getInstance(UserInfo.getUserId());
        List<LoggerSettings__c> testSettingsRecords = new List<LoggerSettings__c>{ orgDefaultSettingsRecord, profileSettingsRecord, userSettingsRecord };
        insert testSettingsRecords;
        Map<Id, LoggerSettings__c> testSettingsRecordsById = queryLoggerSettingsRecords(testSettingsRecords);

        List<LoggerSettingsController.SettingsRecordResult> recordResults = LoggerSettingsController.getRecords();
        System.assertNotEquals(true, recordResults.isEmpty());
        System.assertEquals(testSettingsRecordsById.size(), recordResults.size());
        for (LoggerSettingsController.SettingsRecordResult result : recordResults) {
            LoggerSettings__c matchingRecord = testSettingsRecordsById.get(result.record.Id);
            System.assertNotEquals(null, matchingRecord);
            System.assertEquals(matchingRecord, result.record);
            System.assertEquals(matchingRecord.CreatedBy.Username, result.createdByUsername);
            System.assertEquals(matchingRecord.LastModifiedBy.Username, result.lastModifiedByUsername);
        }
    }

    @IsTest
    static void it_should_create_new_record() {
        LoggerSettings__c expectedNewRecord = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
        LoggerSettings__c newRecord = LoggerSettingsController.createRecord();
        System.assertEquals(expectedNewRecord, newRecord);
        System.assertEquals(null, newRecord.Id);
        System.assertEquals(null, newRecord.SetupOwnerId);
    }

    @IsTest
    static void it_should_save_new_record() {
        LoggerSettings__c newRecord = LoggerSettingsController.createRecord();
        newRecord.SetupOwnerId = UserInfo.getUserId();
        System.assertEquals(null, newRecord.Id);

        LoggerSettingsController.saveRecord(newRecord);
        System.assertNotEquals(null, newRecord.Id);
    }

    @IsTest
    static void it_should_save_existing_record() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c existingRecord = LoggerSettings__c.getOrgDefaults();
        System.assertEquals([SELECT Id FROM Organization].Id, existingRecord.SetupOwnerId);
        System.assertNotEquals(null, existingRecord.Id);

        Boolean originalValue = existingRecord.IsEnabled__c;
        Boolean updatedValue = !originalValue;
        existingRecord.IsEnabled__c = updatedValue;
        LoggerSettingsController.saveRecord(existingRecord);

        existingRecord = LoggerSettings__c.getOrgDefaults();
        System.assertEquals(updatedValue, existingRecord.IsEnabled__c);
    }

    @IsTest
    static void it_should_throw_exception_when_saving_invalid_record() {
        LoggerSettings__c invalidRecord = null;
        try {
            LoggerSettingsController.saveRecord(invalidRecord);
            System.assert(false, 'Expected exception from previous line, this assert should not run');
        } catch (Exception ex) {
            System.assertEquals(AuraHandledException.class.getName(), ex.getTypeName());
        }
    }

    @IsTest
    static void it_should_delete_existing_record() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c existingRecord = LoggerSettings__c.getOrgDefaults();
        System.assertEquals([SELECT Id FROM Organization].Id, existingRecord.SetupOwnerId);
        System.assertNotEquals(null, existingRecord.Id);

        LoggerSettingsController.deleteRecord(existingRecord);

        List<LoggerSettings__c> remainingRecords = [SELECT Id FROM LoggerSettings__c WHERE Id = :existingRecord.Id];
        System.assertEquals(0, remainingRecords.size());
    }

    @IsTest
    static void it_should_throw_exception_when_deleting_invalid_record() {
        LoggerSettings__c invalidRecord = null;
        String expectedExceptionMessage;
        try {
            delete invalidRecord;
        } catch (Exception ex) {
            expectedExceptionMessage = ex.getMessage();
        }

        try {
            LoggerSettingsController.deleteRecord(invalidRecord);
            System.assert(false, 'Expected exception from previous line, this assert should not run');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(expectedExceptionMessage), 'Exception did not contain expected message, received: ' + ex.getMessage());
        }
    }

    @IsTest
    static void it_should_return_organization_record() {
        Organization expectedRecord = [SELECT Id, Name FROM Organization];
        Organization returnedOrganization = LoggerSettingsController.getOrganization();
        System.assertEquals(expectedRecord, returnedOrganization);
    }

    @IsTest
    static void it_should_return_empty_profile_search_results_list_when_no_matches_found() {
        String nonsenseSearchTerm = 'asdfqwert;lkhpoiy';
        List<LoggerSettingsController.SetupOwnerSearchResult> results = LoggerSettingsController.searchForSetupOwner('Profile', nonsenseSearchTerm);
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void it_should_return_profile_search_results_list_when_matches_found() {
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        String searchTerm = '%' + currentProfile.Name.left(4) + '%';
        Map<Id, Profile> expectedResultsById = new Map<Id, Profile>([SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name LIKE :searchTerm]);
        List<LoggerSettingsController.SetupOwnerSearchResult> results = LoggerSettingsController.searchForSetupOwner('Profile', searchTerm);

        System.assertNotEquals(true, results.isEmpty());
        System.assertEquals(expectedResultsById.size(), results.size());
        for (LoggerSettingsController.SetupOwnerSearchResult result : results) {
            Profile matchingProfile = expectedResultsById.get(result.recordId);
            System.assertNotEquals(null, matchingProfile);
            System.assertEquals(matchingProfile.Name, result.label);
            System.assertEquals('License: ' + matchingProfile.UserLicense.Name, result.secondaryLabel);
            System.assertEquals('utility:profile', result.icon);
            System.assertEquals(null, result.image);
        }
    }

    @IsTest
    static void it_should_return_empty_user_search_results_list_when_no_matches_found() {
        String nonsenseSearchTerm = 'asdfqwert;lkhpoiy';
        List<LoggerSettingsController.SetupOwnerSearchResult> results = LoggerSettingsController.searchForSetupOwner('User', nonsenseSearchTerm);
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void it_should_return_user_search_results_list_when_matches_found() {
        String searchTerm = '%' + UserInfo.getFirstName() + '%';
        Map<Id, User> expectedResultsById = new Map<Id, User>(
            [SELECT Id, Name, Username, SmallPhotoUrl FROM User WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm]
        );
        List<LoggerSettingsController.SetupOwnerSearchResult> results = LoggerSettingsController.searchForSetupOwner('User', searchTerm);

        System.assertNotEquals(true, results.isEmpty());
        System.assertEquals(expectedResultsById.size(), results.size());
        for (LoggerSettingsController.SetupOwnerSearchResult result : results) {
            User matchingUser = expectedResultsById.get(result.recordId);
            System.assertNotEquals(null, matchingUser);
            System.assertEquals(matchingUser.Username, result.label);
            System.assertEquals('Name: ' + matchingUser.Name, result.secondaryLabel);
            System.assertEquals('standard:people', result.icon);
            System.assertEquals(matchingUser.SmallPhotoUrl, result.image);
        }
    }

    @IsTest
    static void it_should_throw_exception_when_invalid_setupOwnerType_specified() {
        String invalidSetupOwnerType = 'something else';
        String searchTerm = 'search term doesn\'t matter since the setupOwnerType is invalid';
        String expectedExceptionMessage = 'Invalid SetupOwnerType: ' + invalidSetupOwnerType;

        try {
            LoggerSettingsController.searchForSetupOwner(invalidSetupOwnerType, searchTerm);
            System.assert(false, 'Expected exception from previous line, this assert should not run');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(expectedExceptionMessage), 'Exception did not contain expected message, received: ' + ex.getMessage());
        }
    }

    // Helper methods
    private static Map<Id, LoggerSettings__c> queryLoggerSettingsRecords(List<LoggerSettings__c> recordsToQuery) {
        return new Map<Id, LoggerSettings__c>(
            [
                SELECT
                    CreatedBy.Username,
                    CreatedById,
                    CreatedDate,
                    DefaultLogShareAccessLevel__c,
                    DefaultNumberOfDaysToRetainLogs__c,
                    DefaultSaveMethod__c,
                    Id,
                    IsAnonymousModeEnabled__c,
                    IsApexSystemDebugLoggingEnabled__c,
                    IsDataMaskingEnabled__c,
                    IsEnabled__c,
                    IsJavaScriptConsoleLoggingEnabled__c,
                    LastModifiedBy.Username,
                    LastModifiedById,
                    LastModifiedDate,
                    LoggingLevel__c,
                    SetupOwner.Name,
                    SetupOwner.Type,
                    SetupOwnerId,
                    StripInaccessibleRecordFields__c
                FROM LoggerSettings__c
                WHERE Id IN :recordsToQuery
            ]
        );
    }
}