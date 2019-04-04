/*
+-----------------------+-----------------------------------------------------------------------------+
| Author                | Moshe Asulin (xp16oc@gmail.com)                                    |
+-----------------------+-----------------------------------------------------------------------------+
|- Description: This Class is only an example of how to use the EmailHandlerClass code.
|- Here I'm using a custom object "Investment__c" which has a lookup to Contact, change it as you like in order to meet your needs.
*/
public with sharing class ExampleClass {

     public List<Investment__c> investments {get;set;}
     public List<InvestmentWrapper> InvestmentToUpdate {get;set;}
     public String selectedTemplateName {get;set;}

     public ExampleClass() {
          investments = [SELECT Id, Contact__r.Name, Contact__r.Id FROM Investment__c LIMIT 10];
          InvestmentToUpdate = new List<InvestmentWrapper>();
          selectedTemplateName = 'Email Template Name Here';
     }

	public void sendEmails() {
		List<EmailTemplateHandler> emailHandlerList = new List<EmailTemplateHandler>();
		List<String> bccRecipents = new List<String>{(String) UserInfo.getUserId()};
		Set<Id> queryObjectIds = new Set<Id>();
		Map<Id, Map<String,String>> mergeFields; // Example: (Investment Id, {{!Contact__r.name!}, 'Person name here'})

		// Find Relevant Merge Fields:
		for (InvestmentWrapper invWrapper : InvestmentToUpdate) {
			queryObjectIds.add(invWrapper.investmentId);
		}
		mergeFields = EmailTemplateHandler.getMergeFields(selectedTemplateName, 'Investment__c', queryObjectIds);

		// For each InvestmentWrapper Create an EmailTemplateHandler object:
		for (InvestmentWrapper invWrapper : InvestmentToUpdate) {
			// Build EmailTemplateHandler objects:
			EmailTemplateHandler eth = new EmailTemplateHandler(invWrapper.contactEmail, invWrapper.contactId , bccRecipents, mergeFields.get(invWrapper.investmentId));

			// Add to list of email handlers:
			emailHandlerList.add(eth);
		}
		
		// Create Messaging.SingleEmailMessages from emailHandlerList:
		List<Messaging.SingleEmailMessage> emails = EmailTemplateHandler.prepareEmails(emailHandlerList, selectedTemplateName, 'ourCrowd Support');

		try{
			// Send Emails:
			List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
		}
		catch(Exception e){
			ApexPages.addMessages(e);
			System.Debug('error: ' + e.getMessage()); 
		}
	}

	// Investment Wrapper:
	public class InvestmentWrapper {
		public Investment__c Investment {get;set;}
		public String investmentId {get; set;}
		public Integer num {get; set;}
		public Boolean selected {get; set;}
		public Id contactId {get; set;}
		public String contactEmail {get; set;}

		InvestmentWrapper(Investment__c inv) {
			Investment = inv;
			investmentId = inv.Id;
			selected = true;
			num = FUND_CapitalCallEmails.num += 1;
			contactId = inv.Commitment__r.Contact__c;
			contactEmail = inv.Commitment__r.Contact__r.Email;
		}
	}
}