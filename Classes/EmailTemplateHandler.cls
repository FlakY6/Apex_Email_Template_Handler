/*
+-----------------------+-----------------------------------------------------------------------------+
| Author                | Moshe Asulin (xp16oc@gmail.com)                                    |
+-----------------------+-----------------------------------------------------------------------------+
|- Description: A dynamic tool to replace Merge fields inside Email Templates.
*/

public with sharing class EmailTemplateHandler {

	public String ToAddress;
	public Id ToAddressId;
	public List<String> BccAddresses;
	public Map<String, String> valuesMap;

	// Create an EmailTemplateHandler Object with relevant attributes:
	public EmailTemplateHandler(String toAddr, Id toAddrId, List<String> bccAddr, Map<String, String> mergeMap) {
		ToAddress = toAddr; // Contact Email
		ToAddressId = toAddrId; // Contact or Lead or User Id
		BccAddresses = bccAddr; // Bcc Emails
		valuesMap = mergeMap; // Merge fields to find
	}

	/**
	 * This function receives an email template name and replaces all the merge fields inside of it's body/htmlValue/Subject with relevant values.
	 * This function is building the Merge Fields Map with Key=>value pairs.
	 *
	 * @param  emailTemplateName:  emailTemplateName Name of email template to get merge fields from.
	 * @param  mainObject:         mainObject Name of the object to query from.
	 * @param  queryObjectIds:     queryObjectIds a Set of Id's to query data from (Example: Investment records).
	 * @return  return:            Map of Id and it's merge field keys/values.
	 */
	public static Map<Id, Map<String,String>> getMergeFields(String emailTemplateName, String mainObject, Set<Id> queryObjectIds) {
		Map<Id, Map<String,String>> mergeFieldsValuesByRecord;
		Set<String> mergeFieldKeys;
		EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
								 FROM EmailTemplate 
								 WHERE Name = :emailTemplateName];
		formulas = new Map<String, List<String>>();

		// Merge field can be in Subject/HTMLValue:
		String templateText = emailTemplate.HtmlValue + ' ' + emailTemplate.Subject;
		
		// Find merge fields keys from template:
		mergeFieldKeys = getMergeFieldsKeys(templateText);

		// Find merge fields values:
		mergeFieldsValuesByRecord = getMergeFieldsValues(mergeFieldKeys, mainObject, queryObjectIds);

		// Return Map with each record's key=>value
		return mergeFieldsValuesByRecord;
	}

	// This function parses the body/subject of the Email Template and return all the merge fields it can find in this format: '{!name!}'.
	private static Set<String> getMergeFieldsKeys(String body) {
		Set<String> mergeFields = new Set<String>();
		Integer start = 0;
		Integer stop = 0;

		while (body.contains('{!')) {
			start = body.indexOf('{!');
			stop = body.indexOf('!}') + 2;
			if (!mergeFields.contains(body.substring(start, stop))) {
				mergeFields.add(body.substring(start, stop));
			}

			// remove this loop substring from main string:
			body = body.remove(body.substring(start, stop));
		}
		
		// Search for formula calculations in the email template body:
		while (body.contains('{~')) {
			start = body.indexOf('{~');
			stop = body.indexOf('~}') + 2;
			String mergeFormula = body.substring(start, stop).remove('{~').remove('~}');
			List<String> formula = mergeFormula.split('!');
			
			// Save Formula parts in map:
			formulas.put(body.substring(start, stop), formula);

			// remove this loop substring from main string:
			body = body.remove(body.substring(start, stop));
		}

		return mergeFields;
	}

	/**
	 * This function gets a set of merge fields, a name of object to query from and a set of records to query from and return for each merge field/record it's value.
	 *
	 * @param  keysSet:        keysSet merge fields set
	 * @param  mainObject:     mainObject Name of object to query from.
	 * @param  queryObjectIds: queryObjectIds Set of records to find values for in query.
	 * @return  return:        Map<Id, Map<String,String>> for each record, it's merge fields map.
	 */
	private static Map<Id, Map<String,String>> getMergeFieldsValues(Set<String> keysSet, String mainObject, Set<Id> queryObjectIds){
		Map<Id, Map<String,String>> mergeFieldsValuesByRecord = new Map<Id, Map<String,String>>();
		Map<String, String> keys = new Map<String, String>(); //Example: {{!Commitment__r.Name!} => Commitment__r.Name}
		String queryFields = '';
		String query = '';

		for (String key : keysSet) {
			if (queryFields != ''){
				queryFields += ', ' + key.substringBetween('{!', '!}');
				keys.put(key, key.substringBetween('{!', '!}'));
			}
			else {
				queryFields += key.substringBetween('{!', '!}');
				keys.put(key, key.substringBetween('{!', '!}'));
			}
		}

		// Find each record values with dynamic query:
		query = 'SELECT ' + queryFields + ' FROM ' + mainObject + ' WHERE Id IN: queryObjectIds ';
		List<SObject> sobjList = Database.query(query);

		for (SObject record : sobjList) {
			Map<String, String> mergeFields = new Map<String, String>();
			for (String key : keys.keySet()) {
				String value = keys.get(key);

				// For a related object:
				if (key.contains('.')){
					SObject obj;
					if(key.contains('__r')) {
						obj = record.getSObject(keys.get(key).substringBefore('__r') + '__r'); // Example: Commitment__r.Name
					}
					else {
						obj = record.getSObject(keys.get(key).substringBefore('.')); // Example: AccountId.Name
					}
					value = (String) obj.get(keys.get(key).substringafter('.')); // Example: Name
				}

				// for this object:
				else {
					value = String.valueOf(record.get(keys.get(key))); // Example: Name
				}

				value = formatDecimals(value);
				mergeFields.put(key, value);
			}
			mergeFields = addGenericValues(mergeFields);
			mergeFields = addFormulaValues(mergeFields);
			mergeFieldsValuesByRecord.put(record.Id, mergeFields);
		}

		return mergeFieldsValuesByRecord;
	}

	// Fix Decimal numbers formatting (Example: from 12000 ->12,000)
	private static String formatDecimals(String value){
		// Format Decimal values into Currencies:
		if (Utils.isNumeric(value)){
			value = Utils.formatCurrency(Decimal.valueOf(value));
		}

		return value;
	}

	// Add generic values for each record:
	// Inside the Email Template, generic values must be wrraped with '#' like this: #example#
	private static Map<String, String> addGenericValues(Map<String, String> mergeFields) {
		// Add Today's date:
		mergeFields.put('#Today()#', String.valueOf(date.today()));
		// Add Today's dateTime:
		mergeFields.put('#Now()#', String.valueOf(Datetime.now()));
		// Add Today's year:
		mergeFields.put('#Current_Year#', String.valueOf(Date.today().Year()));
		// Add Today's Month:
		mergeFields.put('#Current_Month#', String.valueOf(Date.today().Month()));
		// Add Today's Day:
		mergeFields.put('#Current_Day#', String.valueOf(Date.today().Day()));

		return mergeFields;
	}

	// Add formula calculations for each record.
	// Inside the Email Template, generic values must be wrraped with '{~'.
	// Operators/field should be seperated with '!'.
	// example: {~example!-!field~}.
	private static Map<String, String> addFormulaValues(Map<String, String> mergeFields) {
		Set<String> Operators = new Set<String>{'-','+','*','/'};

		// For each formula:
		for (String formulaKey : formulas.keySet()) {
			Decimal sum = 0;
			String lastOperator = '+';
			for (String key : formulas.get(formulaKey)) {
				// Number:
				if (!Operators.contains(key)) {
					String n = mergeFields.get('{!'+key+'!}').remove(',');

					if (lastOperator == '+') {
						sum += Decimal.valueOf(n);
					}
					else if (lastOperator == '-') {
						sum -= Decimal.valueOf(n);
					}
					else if (lastOperator == '*') {
						sum = sum * Decimal.valueOf(n);
					}
					else if (lastOperator == '/') {
						sum = sum / Decimal.valueOf(n);
					}
				}
				// Operator:
				else{
					lastOperator = key;
				}
			}

			// Add formula value as mergeField:
			mergeFields.put(formulaKey, formatDecimals(String.valueOf(sum)));
		}

		return mergeFields;
	}

	// This function gets a list of EmailTemplateHandlers and prepeare a Messaging.SingleEmailmessage for each.
	public static List<Messaging.Singleemailmessage> prepareEmails(List<EmailTemplateHandler> listEmailHandlers, String emailTemplateName, String senderDisplayName) {
		List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();
		List<Messaging.SendEmailResult> listEmailResult = null;
		
		EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
								 FROM EmailTemplate 
								 WHERE Name = :emailTemplateName];

		for (EmailTemplateHandler eth : listEmailHandlers) {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setSenderDisplayName(senderDisplayName);

			// Set Email address
			if(eth.ToAddress != null && eth.ToAddress.length() > 0)
				mail.setToAddresses(new String[] { eth.ToAddress });
			else
				mail.setTargetObjectId(eth.ToAddressId);

			// Set Bcc recipients
			String addresses = '';
			if(eth.BccAddresses != null && eth.BccAddresses.size() > 0) {
				for (String bccAdress : eth.BccAddresses) {
					if (addresses != ''){
						addresses += ', ' + bccAdress;
					}
					else {
						addresses += bccAdress;
					}
				}
				mail.setBccAddresses(new String[] {addresses});
			}

			// Set email Subject
			String subject = emailTemplate.Subject;
			for(String key: eth.valuesMap.keySet()){
				subject = subject.replace(key, (eth.valuesMap.get(key) == null ? '' : eth.valuesMap.get(key)));
			}
			mail.setSubject(subject);

			// Set email Body
			String htmlBody = emailTemplate.HtmlValue;
			String plainBody = emailTemplate.Body;
			for (String key : eth.valuesMap.keySet()) {
				htmlBody = htmlBody.replace(key, (eth.valuesMap.get(key) == null ? '' : eth.valuesMap.get(key)));
				plainBody = plainBody.replace(key, (eth.valuesMap.get(key) == null ? '' : eth.valuesMap.get(key)));
			}

			// Final Clean:
			htmlBody = htmlBody.replace(']]>', '');
			plainBody = plainBody.replace(']]>', '');
			
			// build email Message from all parameters:
			mail.setHtmlBody(htmlBody);
			mail.setPlainTextBody(plainBody);
			mail.setSaveAsActivity(false);
			listSingleEmailMessages.add(mail);
		}
		
		return listSingleEmailMessages;
  	}

}