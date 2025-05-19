/**
 * Creates a validation middleware for Express routes
 * @param {Object} schema - Schema to validate against
 * @returns {Function} Express middleware
 */
export const validateRequest = (schema) => {
  return (req, res, next) => {
    try {
      // Determine which part of the request to validate
      const dataToValidate = req.body;
      
      // Validate the data against the schema
      const result = schema.validate(dataToValidate, { abortEarly: false });
      
      if (result.error) {
        // Format validation errors
        const errors = result.error.details.map(error => ({
          field: error.path.join('.'),
          message: error.message
        }));
        
        return res.status(400).json({
          error: 'Validation failed',
          details: errors
        });
      }
      
      // If validation passes, continue to the route handler
      next();
    } catch (error) {
      console.error('Validation middleware error:', error);
      res.status(500).json({ error: 'Internal server error during validation' });
    }
  };
};
