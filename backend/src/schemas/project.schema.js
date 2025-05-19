import Joi from 'joi';

// Project creation schema
export const createProjectSchema = Joi.object({
  title: Joi.string().required().min(3).max(100),
  description: Joi.string().allow('', null),
  clientId: Joi.string().required(),
  status: Joi.string().valid('active', 'completed', 'onhold').default('active')
});

// Project update schema
export const updateProjectSchema = Joi.object({
  title: Joi.string().min(3).max(100),
  description: Joi.string().allow('', null),
  status: Joi.string().valid('active', 'completed', 'onhold')
}).min(1); // At least one field must be present

// Todo creation schema
export const createTodoSchema = Joi.object({
  title: Joi.string().required().min(2).max(100),
  description: Joi.string().allow('', null),
  deadline: Joi.date().iso().allow(null),
  status: Joi.string().valid('pending', 'in_progress', 'completed').default('pending')
});

// Time tracking entry schema
export const timeTrackingSchema = Joi.object({
  startTime: Joi.date().iso().required(),
  endTime: Joi.date().iso().allow(null),
  duration: Joi.number().required().min(1), // Duration in seconds
  todoId: Joi.string().allow(null),
  description: Joi.string().allow('', null)
});
