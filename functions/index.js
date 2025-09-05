const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const nodemailer = require("nodemailer");

initializeApp();

// Email configuration
const emailConfig = {
  service: "gmail",
  auth: {
    user: "a.stark.ch@gmail.com", // Replace with your email
    pass: "npen xegx aeit uyag", // Replace with Gmail app password
  },
};

// Create transporter
const transporter = nodemailer.createTransport(emailConfig);


// Contact form email function
exports.sendContactEmail = onDocumentCreated("contact_messages/{messageId}", async (event) => {
      const messageData = event.data.data();
      const messageId = event.params.messageId;

      try {
        // Email content
        const mailOptions = {
          from: emailConfig.auth.user,
          to: "a.stark.ch@gmail.com", // Replace with your email
          replyTo: messageData.email,
          subject: `New Contact Form Message from ${messageData.name}`,
          html: `
          <h2>New Contact Form Message</h2>
          <p><strong>From:</strong> ${messageData.name} 
          (${messageData.email})</p>
          <p><strong>Company:</strong> ${messageData.company}</p>
          <p><strong>Message:</strong></p>
          <p>${messageData.message.replace(/\n/g, "<br>")}</p>
          <hr>
          <p><em>Sent via Stark Track Contact Form</em></p>
        `,
          text: `
          New Contact Form Message
          
          From: ${messageData.name} (${messageData.email})
          Company: ${messageData.company}
          
          Message:
          ${messageData.message}
          
          ---
          Sent via Stark Track Contact Form
        `,
        };

        // Send email
        await transporter.sendMail(mailOptions);

        // Update status in Firestore
        await event.data.ref.update({
          status: "sent",
          sentAt: FieldValue.serverTimestamp(),
        });

        console.log("Email sent successfully for message:", messageId);
        return null;
      } catch (error) {
        console.error("Error sending email:", error);

        // Update status in Firestore
        await event.data.ref.update({
          status: "failed",
          error: error.message,
          failedAt: FieldValue.serverTimestamp(),
        });

        throw error;
      }
    });

