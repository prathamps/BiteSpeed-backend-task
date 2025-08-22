import pool from "../connection"
import createContactsTable from "./001_create_contacts_table"
import createIdentifyProcedure from "./002_create_identify_procedure"

const runMigrations = async () => {
	try {
		await createContactsTable()
		await createIdentifyProcedure()
		console.log("Migrations completed successfully.")
		pool.end()
	} catch (error) {
		console.error("Migration failed:", error)
		pool.end()
		process.exit(1)
	}
}

runMigrations()
