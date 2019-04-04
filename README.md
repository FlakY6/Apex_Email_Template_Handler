# Apex_Email_Template_Handler
Allow using merge fields from related records in Salesforce's email templates.

Salesforce's email templates are a great tool to create generic templates and send them to your contacts, the problem is is that you are limited to only one level of merge fields to use in your template.

##### example:
If you want to send your contacts email with information from realted Opportunity, you cannot acheive this with Salesforce standart Email Template UI.

I needed a solution that will allow me to use data from realted records, and this is the purpose of this repository.

### Limitations:
My solution is using APEX Query in order to find the related merge fields, which means a few things:

- The solution is limited for 2 levels of related objects relationship, but you can bring data from multiple records (So now you'll be able to bring information from Contact & Opportunity or from Contact & Account etc..).
##### example:
```SELECT Id, (SELECT Id,Name FROM Contacts) FROM Account = 2 levels of relathionship.```

- if it's a lookup relathionship, you can bring data from 5 levels of relathinship (APEX Query limitations).
##### example:
```SELECT Contact.AccountId.OwnerId.Name FROM Contact = 3 levels of relathionship.```


### Steps how to use:
 1) Declare a list of ```List<EmailTemplateHandler>```.
 2) Call ```EmailTemplateHandler.getMergeFields(selectedTemplateName, 'Main Object', queryObjectIds)```.
 3) Loop over your records and create ```EmailTemplateHandler``` for each one of them based on the merge fields found in previous step.
 4) Now call ```EmailTemplateHandler.prepareEmails(emailHandlerList, <EMAIL_TEMPLATE_NAME_HERE>, '<SENDER_NAME_HERE>')``` with the emailHandlerList.
 5) Send the emails as a ```List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails)```.
 Example can be found here: "FUND_CapitalCallEmails" class, "sendEmails" Method.