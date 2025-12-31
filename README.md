# Contact Tracing App

Forked from [Manish Choudhari's Salesforce Apex Development course](https://github.com/choudharymanish8585/contact-tracing) for learning purposes.

## About

Sample Contact Tracing app built on Salesforce Platform as part of the Udemy course "Salesforce Apex Development."

## My Additions

- All classes
- *(Will update as I complete challenges)*

## Original Setup Instructions

### Install Object Schema
1. Clone "schema-metadata" branch: `git clone --branch schema-metadata https://github.com/LuisAlbertoSalazar/contact-tracing.git`
2. Authorize your org: `sf org login web -a DevOrg`
3. Deploy metadata: `sf project deploy start -d force-app`
4. Assign permission set: `sf org assign permset -n Health_Admin`
5. Open org: `sf org open`

### Install Entire Application
1. Clone "master" branch: `git clone https://github.com/LuisAlbertoSalazar/contact-tracing.git`
2. Follow steps 2-5 above
