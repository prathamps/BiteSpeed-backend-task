import createContactsTable from "./001_create_contacts_table"
import createIdentifyProcedure from "./002_create_identify_procedure"

const runMigrations = async () => {
	await createContactsTable()
	await createIdentifyProcedure()
	console.log("Migrations completed successfully.")
}

runMigrations()
