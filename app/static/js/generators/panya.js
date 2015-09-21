/**
 * Visual Blocks Language
 *
 * Copyright 2012 Google Inc.
 * http://blockly.googlecode.com/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

goog.provide('Blockly.Python.variables');

goog.require('Blockly.Python');

Blockly.Python['panya_pin'] = function(block) {
  var value_pin = Blockly.Python.valueToCode(block, 'pin', Blockly.Python.ORDER_NONE) || '0';
  var dropdown_state = block.getFieldValue('logicstate');
  var code = 'Panya.PanyaPin('+"\'"+value_pin+''+"\'"+"\,"+"\'"+dropdown_state+""+"\')\n";
  if (!Blockly.Python.definitions_['import_panya']){
  Blockly.Python.definitions_['import_panya'] = 'import panya\nPanya=panya.Panya()';
  }
  return code;
};

Blockly.Python['panya_stop'] = function(block) {
  // Stop the panyabot. Change the value of code to the appropriate python function
  var code = 'Panya.PanyaStop()\n';
  if (!Blockly.Python.definitions_['import_panya']) {
	Blockly.Python.definitions_['import_panya'] = 'import panya\nPanya=panya.Panya()';
	}
  return code;
};

Blockly.Python['panya_move'] = function(block) {
  // Passed argument is the time for which we want panya to move
  var dropdown_longdir = block.getFieldValue('longdir');
  // Move the translate the panyabot through the given displacement vector
  var code = 'Panya.PanyaMove('+"\'"+dropdown_longdir+""+"\')\n";
  if (!Blockly.Python.definitions_['import_panya']){
	Blockly.Python.definitions_['import_panya'] = 'import panya\nPanya=panya.Panya()';
	}
  return code;
};

Blockly.Python['panya_turn'] = function(block) {
  var dropdown_latdir = block.getFieldValue('latdir');
  // Turn the panyabot in the specified direction
  var code = 'Panya.PanyaTurn('+"\'"+dropdown_latdir+""+"\')\n";
  if (!Blockly.Python.definitions_['import_panya']) {
	Blockly.Python.definitions_['import_panya'] = 'import panya\nPanya=panya.Panya()';
	}
  return code;
};

Blockly.Python['panya_set_speed'] = function(block) {
  var value_speed = Blockly.Python.valueToCode(block, 'SPEED', Blockly.Python.ORDER_NONE) || '0';
  // Set the panyabot's speed to the given value
  var code = 'Panya.PanyaSetSpeed('+"\'"+value_speed+""+"\')\n";
  if (!Blockly.Python.definitions_['import_panya']) {
	Blockly.Python.definitions_['import_panya'] = 'import panya\nPanya=panya.Panya()';
	}
  return code;
};