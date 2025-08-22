import pool from "../connection"

const createContactsTable = async () => {
	const query = `
    CREATE TABLE IF NOT EXISTS contacts (
      id SERIAL PRIMARY KEY,
      phone_number VARCHAR(20),
      email VARCHAR(255),
      linked_id INTEGER REFERENCES contacts(id),
      link_precedence VARCHAR(10) NOT NULL CHECK (link_precedence IN ('primary', 'secondary')),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP
    );
  `

	try {
		await pool.query(query)
		console.log("Contacts table created successfully")
	} catch (error) {
		console.error("Error creating contacts table:", error)
	}
}

export default createContactsTable
