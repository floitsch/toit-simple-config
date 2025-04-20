STYLES-CSS ::= """
/*
Copyright (C) 2025 Toit contributors
Use of this source code is governed by an MIT-style license that can be
found in the LICENSE file.
*/

:root {
  --primary-color: #2563eb;
  --primary-hover: #1d4ed8;
  --bg-color: #f8fafc;
  --text-color: #1e293b;
  --border-color: #e2e8f0;
  --modified-color: #f59e0b;
}

/* Base styles */
body {
  font-family: system-ui, -apple-system, sans-serif;
  margin: 0;
  padding: 20px;
  background: var(--bg-color);
  color: var(--text-color);
}

/* Common input styles */
input[type="text"],
input[type="number"],
input[type="url"],
input[type="password"] {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  font-size: 1rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

/* Header styles */
#header {
  margin-bottom: 2rem;
}

/* Category components */
.category {
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin: 1rem 0;
  background: white;
}

.category-header {
  padding: 1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
}

.category-header:hover {
  background: #f1f5f9;
}

.category-content {
  padding: 1rem;
}

.category-title {
  margin: 0;
  flex-grow: 1;
}

.category-description {
  color: #64748b;
  margin: 0.5rem 0;
}

/* Value item components */
.value-item {
  margin: 1rem 0;
  padding: 1rem;
  border: 1px solid var(--border-color);
  border-radius: 6px;
}

.value-item.modified {
  border-left: 4px solid var(--modified-color);
}

.value-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}

.value-title {
  margin: 0;
  min-width: 200px;
  flex-shrink: 0;
}

.value-input {
  flex: 1;
  min-width: 0;
  margin-right: 1rem;
}

.value-input input[type="text"],
.value-input input[type="number"],
.value-input input[type="url"],
.value-input input[type="password"] {
  width: 100%;
  max-width: 100%;
  box-sizing: border-box;
}

/* Enum select styles */
.value-input select {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  font-size: 1rem;
  background: white;
  color: var(--text-color);
  appearance: none;
  background-image: url('data:image/svg+xml;charset=US-ASCII,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 5"><path fill="%2364748b" d="M2 0L0 2h4zm0 5L0 3h4z"/></svg>');
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  background-size: 0.65em auto;
}

.value-input select:focus {
  border-color: var(--primary-color);
  outline: none;
}

.value-type {
  font-size: 0.875rem;
  color: #64748b;
  padding: 0.25rem 0.5rem;
  background: #f1f5f9;
  border-radius: 4px;
  flex-shrink: 0;
  white-space: nowrap;
}

.value-description {
  color: #64748b;
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.value-default {
  font-size: 0.875rem;
  color: #64748b;
  margin-top: 0.5rem;
}

/* List components */
.list-container {
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin: 1rem 0;
  padding: 1rem;
  background: white;
}

.list-actions {
  margin-top: 1rem;
}

.list-item {
  position: relative;
  padding-right: 40px;
  margin-bottom: 1rem;
}

/* Secret input components */
.secret-container {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.secret-container input {
  flex: 1;
  min-width: 0;
}

/* Button styles */
.delete-button {
  position: absolute;
  right: 0;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  padding: 8px;
  cursor: pointer;
  color: #cbd5e1;
  transition: color 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.delete-button:hover {
  color: #ef4444;
}

.primary-button {
  background: var(--primary-color);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.primary-button:hover {
  background: var(--primary-hover);
}

.secondary-button {
  background: white;
  border: 1px solid var(--border-color);
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
}

.secondary-button:hover {
  background: #f1f5f9;
}

.toggle-password {
  background: none;
  border: none;
  cursor: pointer;
  color: #64748b;
}

.toggle-password:hover {
  color: var(--text-color);
}

/* Save button */
#saveButton {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 999;
  background: var(--primary-color);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}

#saveButton:hover {
  background: var(--primary-hover);
}

#saveButton:disabled {
  background: var(--border-color);
  cursor: not-allowed;
}

/* Toggle switch component */
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 48px;
  height: 24px;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #cbd5e1;
  transition: .3s;
  border-radius: 24px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .3s;
  border-radius: 50%;
}

.toggle-switch input:checked + .toggle-slider {
  background-color: var(--primary-color);
}

.toggle-switch input:checked + .toggle-slider:before {
  transform: translateX(24px);
}

/* Toast notifications */
.toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1000;
}

.toast {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: white;
  border-radius: 8px;
  padding: 12px 16px;
  margin: 8px;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  transition: all 0.3s ease;
  opacity: 0;
  transform: translateY(100%);
}

.toast.show {
  opacity: 1;
  transform: translateY(0);
}

.toast.success {
  border-left: 4px solid #22c55e;
}

.toast.error {
  border-left: 4px solid #ef4444;
}

.toast i {
  font-size: 18px;
}

.toast.success i {
  color: #22c55e;
}

.toast.error i {
  color: #ef4444;
}

"""
