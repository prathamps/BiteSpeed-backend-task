import { Request, Response } from "express"
import { ContactRequest, ContactResponse } from "../types"
import pool from "../database/connection"

export const identifyContact = async (req: Request, res: Response) => {
	const { email, phoneNumber }: ContactRequest = req.body

	try {
		const result = await pool.query(
			"SELECT identify_contact($1, $2) as contact_data",
			[email, phoneNumber]
		)

		const contactData: ContactResponse = result.rows[0].contact_data
		res.json(contactData)
	} catch (error) {
		console.error("Error in identify:", error)
		res.status(500).json({ error: "Internal server error" })
	}
}
