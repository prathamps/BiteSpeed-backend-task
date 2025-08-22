import pool from "../connection"
import fs from "fs"
import path from "path"

const createIdentifyProcedure = async () => {
	const procedurePath = path.join(__dirname, "../procedures/identify.sql")
	const procedureSql = fs.readFileSync(procedurePath, "utf8")

	try {
		await pool.query(procedureSql)
		console.log("Identify procedure created successfully")
	} catch (error) {
		console.error("Error creating identify procedure:", error)
	}
}

export default createIdentifyProcedure
