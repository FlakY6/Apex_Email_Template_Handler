# Apex_Email_Template_Handler
# Allow using merge fields from related records in Salesforce's email templates.

Salesforce's email templates are a great tool to create generic templates and send them to your contacts, the problem is is that you are limited to only one level of merge fields to use in your template.

_example_:
If you want to send your contacts email with information from realted Opportunity, you cannot acheive this with Salesforce standart Email Template UI.

I needed a solution that will allow me to use data from realted records, and this is the purpose of this repository.

##Limitations:
My solution is using APEX Query in order to find the related merge fields, which means a few things:

- The solution is limited for 2 levels of related objects relationship, but you can bring data from multiple records (So now you'll be able to bring information from Contact & Opportunity or from Contact & Account etc..).
_example_:
SELECT Id, (SELECT Id,Name FROM Contacts) FROM Account = 2 levels of relathionship.

- if it's a lookup relathionship, you can bring data from 5 levels of relathinship (APEX Query limitations).
_example_:
SELECT Contact.AccountId.OwnerId.Name FROM Contact = 3 levels of relathionship.
