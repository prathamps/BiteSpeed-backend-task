export interface Contact {
	id: number
	phoneNumber?: string
	email?: string
	linkedId?: number
	linkPrecedence: "primary" | "secondary"
	createdAt: Date
	updatedAt: Date
	deletedAt?: Date
}

export interface ContactRequest {
	email?: string
	phoneNumber?: string
}

export interface ContactResponse {
	contact: {
		primaryContactId: number
		emails: string[]
		phoneNumbers: string[]
		secondaryContactIds: number[]
	}
}
