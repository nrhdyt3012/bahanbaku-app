// Error yang aman ditampilkan ke client (status + pesan + detail per field)
class AppError extends Error {
  constructor(status, message, errors = null) {
    super(message);
    this.status = status;
    this.errors = errors;
  }
}
module.exports = AppError;
