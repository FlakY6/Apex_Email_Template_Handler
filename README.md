# Apex_Email_Template_Handler
Allow using merge fields from related records in Salesforce's email templates.

Salesforce's email templates are a great tool for creating generic templates and send them to your contacts, the problem is is that you are limited to only one level of merge fields to use in your template.

##### Example:
If you want to send your contacts an email with information from realted Opportunity, you cannot achieve this with Salesforce standard Email Template UI.

I needed a solution that will allow me to use data from realted records, and this is the purpose of this repository.

### Limitations:
My solution is using APEX Query in order to find the related merge fields of a give record, which means a few things:

- This solution only works from APEX Code and not from Salesforce's UI.
- The solution is limited for 2 levels of related objects relationship, but you can bring data from multiple records (So now you'll be able to bring information from Contact & Opportunity or from Contact & Account etc..).
- For Related list relationship:
##### Example:
```SELECT Id, (SELECT Id,Name FROM Contacts) FROM Account = 2 levels of relathionship.```

- For lookup relationships, you can bring data from 5 levels of relationship (APEX Query limitations).
##### Example:
```SELECT Contact.AccountId.OwnerId.Name FROM Contact = 3 levels of relathionship.```


### Steps how to use:

First, deploy EmailTemplateHandler Class to your Org.
*Second and Most important:* In your email template, wrap your merge fields with ```{!<mergerFieldHere>!}```
 ##### Example:
 ```Hello {!Contact__r.Name!}, how are you?```

 1) Declare a list of ```List<EmailTemplateHandler>```.

 2) Call ```EmailTemplateHandler.getMergeFields(selectedEmailTemplateName, 'Main Object', queryObjectIds)``` where ```Main Object``` is the FROM Object and ```queryObjectIds``` is a Set of Ids of the records you want to send emails to.
 (This parameters goes to a dynamic query and return data based on them).

 3) Loop over your records and create ```EmailTemplateHandler``` for each one of them based on the merge fields found in previous step.

 4) Now call ```EmailTemplateHandler.prepareEmails(emailHandlerList, <EMAIL_TEMPLATE_NAME_HERE>, '<SENDER_NAME_HERE>')``` with the emailHandlerList.
 
 5) Send the emails as a ```List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails)```.
 
 Example can be found here: "ExampleClass.cls" class, "sendEmails" Method.