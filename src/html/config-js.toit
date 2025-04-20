CONFIG-JS ::= """
// Copyright (C) 2025 Toit contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

class ConfigManager {
  constructor() {
    this.schema = null;
    this.values = {};
    this.modifiedValues = new Set();
    this.categoryOpened = {};  // Whether a category is open or closed.
    this.init();
    this.setupToastContainer();
  }

  // Initialization and API methods.
  async init() {
    try {
      await this.fetchSchema();
      await this.fetchValues();
      this.render();
      this.setupEventListeners();
    } catch (error) {
      console.error('Initialization failed:', error);
    }
  }

  setupEventListeners() {
    const saveButton = document.getElementById('saveButton');
    saveButton.addEventListener('click', () => this.saveValues());
    this.updateSaveButtonState();

    // Add keyboard shortcut for saving (Ctrl/Cmd + S).
    document.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        if (!saveButton.disabled) {
          this.saveValues();
        }
      }
    });
  }

  // Toast notification system.
  setupToastContainer() {
    const container = this.createElement('div', 'toast-container');
    document.body.appendChild(container);
  }

  showToast(message, type = 'success', duration = 3000) {
    const container = document.querySelector('.toast-container');
    const toast = this.createElement('div', `toast \${type}`);

    const icon = this.createElement('i', type === 'success' ? 'fas fa-check-circle' : 'fas fa-exclamation-circle');
    const text = this.createElement('span');
    text.textContent = message;

    toast.appendChild(icon);
    toast.appendChild(text);
    container.appendChild(toast);

    // Add click handler for dismissal
    toast.addEventListener('click', () => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    });

    // Trigger reflow to enable transition.
    toast.offsetHeight;
    toast.classList.add('show');

    // Auto-dismiss after duration
    const timeout = setTimeout(() => {
      if (toast.parentElement) { // Only dismiss if toast still exists
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
      }
    }, duration);
  }

  // API interactions.
  async fetchValues() {
    const response = await fetch('/values');
    this.values = await response.json();
  }

  async fetchSchema() {
    const response = await fetch('/schema');
    this.schema = await response.json();
  }

  async saveValues() {
    try {
      const response = await fetch('/update', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.values)
      });

      if (response.ok) {
        this.modifiedValues.clear();
        this.updateSaveButtonState(); // Update the save button state

        // Remove the 'modified' class from all inputs.
        const modifiedElements = document.querySelectorAll('.value-item.modified');
        modifiedElements.forEach(el => {
          el.classList.remove('modified');
        });

        this.showToast('Configuration saved successfully');
      }
    } catch (error) {
      console.error('Save failed:', error);
      this.showToast('Failed to save configuration', 'error');
    }
  }

  // DOM helper methods.
  createElement(tag, className = '', attributes = {}) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    Object.entries(attributes).forEach(([key, value]) => {
      element.setAttribute(key, value);
    });
    return element;
  }

  createButton(text, className = '', onClick = null) {
    const button = this.createElement('button', className);
    button.textContent = text;
    if (onClick) button.addEventListener('click', onClick);
    return button;
  }

  createToggleSwitch(checked, onChange) {
    const label = this.createElement('label', 'toggle-switch');
    const input = this.createElement('input', '', {
      type: 'checkbox',
    });
    input.checked = checked;
    input.addEventListener('change', onChange);

    const slider = this.createElement('span', 'toggle-slider');
    label.appendChild(input);
    label.appendChild(slider);
    return label;
  }

  // Data management methods.
  getDefaultValue(schema) {
    // If schema defines a default, use it
    if (schema.default !== undefined) return schema.default;

    // Otherwise use reasonable defaults based on type
    switch (schema.type) {
      case 'object':
        const obj = {};
        if (schema.properties) {
          Object.entries(schema.properties).forEach(([key, prop]) => {
            obj[key] = this.getDefaultValue(prop);
          });
        }
        return obj;
      case 'array':
        return [];
      case 'boolean':
        return false;
      case 'number':
      case 'integer':
        return 0;
      case 'string':
        return '';
      default:
        return null;
    }
  }

  getSchemaForPath(path) {
    let schema = this.schema;
    if (!schema) return null;

    for (let i = 0; i < path.length; i++) {
      const part = path[i];
      if (!schema) return null;

      // If we're dealing with an array (number index).
      if (!isNaN(part)) {
        // If the current schema is an array type, use its items schema.
        if (schema.type === 'array' && schema.items) {
          schema = schema.items;
          continue;
        }
      }

      if (schema.type === 'object' && schema.properties && schema.properties[part]) {
        schema = schema.properties[part];
      } else if (schema.type === 'array' && schema.items) {
        schema = schema.items;
      } else if (schema.oneOf && schema.properties) {
        // Find the property that controls oneOf (discriminator).
        let typeProperty = null;
        let typePropertyName = null;

        const firstOneOf = schema.oneOf[0];
        // Find the 'const' property in the first oneOf schema.
        if (firstOneOf && firstOneOf.properties) {
          for (const [key, property] of Object.entries(firstOneOf.properties)) {
            if (property.const !== undefined) {
              typeProperty = schema.properties[key];
              typePropertyName = key;
              break;
            }
          }
        }

        // If we found a controlling property, check if we need to use a oneOf schema.
        if (typeProperty && typePropertyName) {
          // Get the current value of the type property.
          const typePropertyPath = path.slice(0, i).concat(typePropertyName);
          const typeValue = this.getValue(typeProperty, typePropertyPath.join('.'));

          // Find the matching oneOf schema.
          const matchingSchema = schema.oneOf.find(
            oneOfSchema =>
              oneOfSchema.properties &&
              oneOfSchema.properties[typePropertyName] &&
              oneOfSchema.properties[typePropertyName].const === typeValue
          );

          // If we found a matching schema and the property exists there, use it.
          if (matchingSchema &&
              matchingSchema.properties &&
              matchingSchema.properties[part]) {
            schema = matchingSchema.properties[part];
            continue;
          }
        }
        // If the property 'part' was not found in a matching oneOf schema,
        // try finding it in the main properties again (it might be a property
        // defined outside the oneOf structure).
        if (schema.properties && schema.properties[part]) {
          schema = schema.properties[part];
        } else {
          // Property not found anywhere relevant.
          return null;
        }
      }
    }
    return schema;
  }

  getValue(schema, id) {
    const parts = id.split('.');
    let current = this.values;

    // First try to get the actual value
    for (const part of parts) {
      if (current === undefined || current === null) break;
      current = current[part];
    }

    // If no value exists, try to get the default from schema
    if (current === undefined || current === null) {
      if (schema) {
        return this.getDefaultValue(schema);
      }
    }

    return current;
  }

  setValue(id, value) {
    const parts = id.split('.');
    const schema = this.getSchemaForPath(parts);

    // Validate and convert the value based on schema type
    let finalValue = value;
    if (schema && (schema.type === 'number' || schema.type === 'integer')) {
      if (value === "" || value === null || value === undefined || isNaN(value)) {
        finalValue = schema.default !== undefined ? schema.default : 0;
      } else {
        finalValue = schema.type === 'integer' ? parseInt(value) : parseFloat(value);
      }
    }

    let current = this.values;
    for (let i = 0; i < parts.length - 1; i++) {
      if (!current[parts[i]]) current[parts[i]] = {};
      current = current[parts[i]];
    }
    current[parts[parts.length - 1]] = finalValue;
    this.modifiedValues.add(id);
    this.updateSaveButtonState();
  }

  // Rendering methods.
  createValueInput(schema, id) {
    const container = this.createElement('div', 'value-item');
    if (this.modifiedValues.has(id)) container.classList.add('modified');

    const header = this.createElement('div', 'value-header');
    const title = this.createElement('h3', 'value-title');
    title.textContent = schema.title;
    header.appendChild(title);

    const inputContainer = this.createElement('div', 'value-input');
    const value = this.getValue(schema, id);

    switch (schema.type) {
      case 'boolean':
        const toggle = this.createToggleSwitch(value, (e) => {
          this.setValue(id, e.target.checked);
          container.classList.add('modified');
        });
        inputContainer.appendChild(toggle);
        break;

      case 'string':
        if (schema.enum) {
          const select = this.createElement('select', 'enum-select', {
            'id': id.replace(/\\./g, '-')
          });
          schema.enum.forEach(option => {
            const optionElement = this.createElement('option');
            optionElement.value = option;
            optionElement.textContent = option;
            if (option === value) optionElement.selected = true;
            select.appendChild(optionElement);
          });
          select.addEventListener('change', (e) => {
            this.setValue(id, e.target.value);
            container.classList.add('modified');
          });
          inputContainer.appendChild(select);
          // Check that the default value is one of the enum values.
          if (schema.default !== undefined && !schema.enum.includes(schema.default)) {
            console.warn(`Default value \${schema.default} is not in enum values`);
          }
        } else if (schema.format === 'password') {
          const secretContainer = this.createElement('div', 'secret-container');
          const input = this.createElement('input', '', {
            type: 'password',
            value: value || ''
          });
          const toggleBtn = this.createButton('👁️', 'toggle-password');
          toggleBtn.addEventListener('click', () => {
            input.type = input.type === 'password' ? 'text' : 'password';
          });
          input.addEventListener('input', (e) => {
            this.setValue(id, e.target.value);
            container.classList.add('modified');
          });
          secretContainer.appendChild(input);
          secretContainer.appendChild(toggleBtn);
          inputContainer.appendChild(secretContainer);
        } else {
          const textInput = this.createElement('input', '', {
            type: schema.format === 'uri' ? 'url' : 'text',
            value: value || ''
          });
          textInput.addEventListener('input', (e) => {
            this.setValue(id, e.target.value);
            container.classList.add('modified');
          });
          inputContainer.appendChild(textInput);
        }
        break;

      case 'integer':
      case 'number':
        const numInput = this.createElement('input', '', {
          type: 'number',
          step: schema.type === 'number' ? 'any' : '1',
          value: value
        });
        numInput.addEventListener('input', (e) => {
          let finalValue;
          if (e.target.value === '') {
            finalValue = schema.default !== undefined ? schema.default : 0;
          } else {
            finalValue = schema.type === 'integer' ?
              parseInt(e.target.value) : parseFloat(e.target.value);
          }
          this.setValue(id, finalValue);
          container.classList.add('modified');
        });
        inputContainer.appendChild(numInput);
        break;
    }

    header.appendChild(inputContainer);

    const type = this.createElement('span', 'value-type');
    type.textContent = schema.type;
    if (schema.enum) type.textContent = 'enum';
    if (schema.format) type.textContent = schema.format;
    header.appendChild(type);

    container.appendChild(header);

    if (schema.description) {
      const description = this.createElement('div', 'value-description');
      description.textContent = schema.description;
      container.appendChild(description);
    }

    if (schema.default !== undefined) {
      const defaultValue = this.createElement('div', 'value-default');
      defaultValue.textContent = `Default: \${schema.default}`;
      container.appendChild(defaultValue);
    }

    return container;
  }

  createCategory(schema, id) {
    const safeId = id.replace(/\\./g, '-');
    const container = this.createElement('div', 'category', { "id": safeId });

    const header = this.createElement('div', 'category-header');
    const title = this.createElement('h2', 'category-title');
    title.textContent = schema.title;
    header.appendChild(title);

    const toggleIcon = this.createElement('i', 'fas fa-chevron-down');
    header.appendChild(toggleIcon);

    const content = this.createElement('div', 'category-content');

    if (this.categoryOpened[id] === undefined) {
      this.categoryOpened[id] = !schema.folded;
    }
    const isOpen = this.categoryOpened[id];
    content.style.display = isOpen ? 'block' : 'none';
    toggleIcon.className = isOpen ? 'fas fa-chevron-up' : 'fas fa-chevron-down';

    if (schema.description) {
      const description = this.createElement('div', 'category-description');
      description.textContent = schema.description;
      content.appendChild(description);
    }

    header.addEventListener('click', () => {
      const isHidden = content.style.display === 'none';
      content.style.display = isHidden ? 'block' : 'none';
      toggleIcon.className = isHidden ? 'fas fa-chevron-up' : 'fas fa-chevron-down';

      this.categoryOpened[id] = !isHidden;
    });

    // Track oneOf sections if they exist.
    const oneOfSections = [];
    let discriminatorProperty = null; // Can be enum or boolean schema
    let discriminatorPropertyId = null;
    let discriminatorType = null; // 'enum' or 'boolean'

    // Identify the discriminator property that controls oneOf, if present..
    if (schema.oneOf && schema.properties && schema.oneOf.length > 0) {
      const firstOneOf = schema.oneOf[0];
      if (firstOneOf.properties) {
        for (const [key, property] of Object.entries(firstOneOf.properties)) {
          if (property.const !== undefined) {
            // Found the potential discriminator key in oneOf, now find it in main properties.
            if (schema.properties[key]) {
              discriminatorProperty = schema.properties[key];
              if (discriminatorProperty.enum) {
                discriminatorType = 'enum';
              } else if (discriminatorProperty.type === 'boolean') {
                discriminatorType = 'boolean';
              } else {
                console.warn(`Discriminator property '\${key}' must be enum or boolean`);
                discriminatorProperty = null; // Invalid discriminator type.
                continue;
              }
              discriminatorProperty.name = key; // Store name for later use.
              discriminatorPropertyId = `\${id}.\${key}`;
              break; // Assume first const property found is the discriminator.
            } else {
              console.warn(`oneOf schema uses property '\${key}' as discriminator, but it's not defined in main properties`);
            }
          }
        }
      } else {
        console.warn('oneOf schema must have properties defined');
      }
    }

    // Render standard properties.
    if (schema.properties) {
      Object.entries(schema.properties).forEach(([key, property]) => {
        const propertyId = `\${id}.\${key}`;
        const element = this.renderSchema(property, propertyId);
        if (element) {
          content.appendChild(element);

          // If this is the discriminator property, add change listener.
          if (propertyId === discriminatorPropertyId && schema.oneOf) {
            if (discriminatorType === 'enum') {
              const enumSelect = element.querySelector('select');
              if (enumSelect) {
                enumSelect.addEventListener('change', (e) => {
                  this.updateOneOfVisibility(oneOfSections, e.target.value);
                });
              }
            } else if (discriminatorType === 'boolean') {
              const toggleInput = element.querySelector('input[type="checkbox"]');
              if (toggleInput) {
                  toggleInput.addEventListener('change', (e) => {
                    this.updateOneOfVisibility(oneOfSections, e.target.checked);
                  });
              }
            }
          }
        }
      });
    }

    // Handle oneOf schemas if present.
    if (schema.oneOf && discriminatorProperty) {
      const oneOfContainer = this.createElement('div', 'oneOf-container');
      content.appendChild(oneOfContainer);

      const currentValue = this.getValue(discriminatorProperty, discriminatorPropertyId);

      // Create a section for each oneOf schema.
      schema.oneOf.forEach((oneOfSchema, index) => {
        // Check for the discriminator property with a 'const' value.
        if (!oneOfSchema.properties || !oneOfSchema.properties[discriminatorProperty.name] || oneOfSchema.properties[discriminatorProperty.name].const === undefined) {
          console.warn(`oneOf schema at index \${index} doesn't have the discriminator const property '\${discriminatorProperty.name}'`);
          return;
        }

        const oneOfConstValue = oneOfSchema.properties[discriminatorProperty.name].const;
        // Store data-type as string for consistent comparison in updateOneOfVisibility.
        const dataTypeString = String(oneOfConstValue);
        const oneOfSection = this.createElement('div', 'oneOf-section', {
          'data-type': dataTypeString,
          'id': `\${safeId}-\${dataTypeString}-section` // Use const value in ID.
        });

        // Hide sections that don't match the current value.
        oneOfSection.style.display = currentValue === oneOfConstValue ? 'block' : 'none';

        // Render all properties in this oneOf schema.
        if (oneOfSchema.properties) {
          Object.entries(oneOfSchema.properties).forEach(([key, property]) => {
            // Skip discriminator property itself as it's already rendered from main properties.
            if (key === discriminatorProperty.name) return;

            const propertyId = `\${id}.\${key}`; // Property ID remains the same regardless of oneOf branch.
            const element = this.renderSchema(property, propertyId);
            if (element) oneOfSection.appendChild(element);
          });
        }

        oneOfContainer.appendChild(oneOfSection);
        oneOfSections.push(oneOfSection);
      });
    }

    container.appendChild(header);
    container.appendChild(content);
    return container;
  }

  // Helper method to update oneOf section visibility.
  updateOneOfVisibility(sections, selectedValue) {
    // Convert selectedValue to string for comparison with data-type attribute.
    const selectedValueString = String(selectedValue);
    sections.forEach(section => {
      const type = section.getAttribute('data-type');
      section.style.display = type === selectedValueString ? 'block' : 'none';
    });
  }

  createList(schema, id) {
    const container = this.createElement('div', 'list-container');

    const title = this.createElement('h2', 'list-title');
    title.textContent = schema.title;
    container.appendChild(title);

    if (schema.description) {
      const description = this.createElement('div', 'list-description');
      description.textContent = schema.description;
      container.appendChild(description);
    }

    const listContent = this.createElement('div', 'list-content');
    const values = this.getValue(schema, id) || [];

    values.forEach((value, index) => {
      const itemContainer = this.createElement('div', 'list-item');
      const element = this.renderSchema(schema.items, `\${id}.\${index}`);
      if (element) itemContainer.appendChild(element);

      if (!schema.minItems || values.length > schema.minItems) {
        const deleteButton = this.createElement('button', 'delete-button');
        const icon = this.createElement('i', 'fas fa-times');
        deleteButton.appendChild(icon);
        deleteButton.addEventListener('click', () => {
          values.splice(index, 1);
          this.setValue(id, values);
          this.render();
        });
        itemContainer.appendChild(deleteButton);
      }

      listContent.appendChild(itemContainer);
    });

    container.appendChild(listContent);

    if (!schema.maxItems || values.length < schema.maxItems) {
      const addBtn = this.createButton('Add Item', 'secondary-button', () => {
        values.push(this.getDefaultValue(schema.items));
        this.setValue(id, values);
        this.render();
      });
      const actions = this.createElement('div', 'list-actions');
      actions.appendChild(addBtn);
      container.appendChild(actions);
    }

    return container;
  }

  renderSchema(schema, id) {
    switch (schema.type) {
      case 'object':
        return this.createCategory(schema, id);
      case 'array':
        return this.createList(schema, id);
      case 'string':
      case 'number':
      case 'integer':
      case 'boolean':
        return this.createValueInput(schema, id);
      default:
        console.warn('Unknown schema type:', schema.type);
        return null;
    }
  }

  updateSaveButtonState() {
    const saveButton = document.getElementById('saveButton');
    saveButton.disabled = this.modifiedValues.size === 0;
    saveButton.classList.toggle('modified', this.modifiedValues.size > 0);
  }

  render() {
    const content = document.getElementById('content');
    content.innerHTML = '';

    if (this.schema.title) {
      document.getElementById('mainTitle').textContent = this.schema.title;
    }

    if (this.schema.description) {
      document.getElementById('mainDescription').textContent = this.schema.description;
    }

    if (this.schema.properties) {
      Object.entries(this.schema.properties).forEach(([key, schema]) => {
        const element = this.renderSchema(schema, key);
        if (element) content.appendChild(element);
      });
    }

    this.updateSaveButtonState();
  }
}

// Initialize the configuration manager when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.configManager = new ConfigManager();
});

"""
