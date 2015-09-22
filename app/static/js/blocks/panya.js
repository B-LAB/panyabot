/**
 * Visual Blocks Editor
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

goog.provide('Blockly.Blocks.variables');

goog.require('Blockly.Blocks');

Blockly.Blocks['panya_pin'] = {
  init: function() {
    this.appendValueInput("pin")
        .setCheck("Number")
        .appendTitle("switch pin")
        .appendField("");
    this.appendDummyInput()
        .appendField(new Blockly.FieldDropdown([["ON", "I"], ["OFF", "O"]]), "logicstate");
    this.setInputsInline(true);
    this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setColour(160);
    this.setTooltip('Turn on or off the chosen pin');
    this.setHelpUrl('http://www.example.com/');
  }
};

Blockly.Blocks['panya_move'] = {
    init: function() {
        this.appendDummyInput()
            .appendTitle("move")
            .appendTitle(new Blockly.FieldDropdown([["forward", "F"], ["backward", "B"]]), "longdir");
        this.setInputsInline(true);
        this.setPreviousStatement(true);
        this.setNextStatement(true);
        this.setTooltip('Give the time for which you want panyabot to move forward');
        this.setHelpUrl('http://www.example.com/');
        this.setColour(160);
  }
};

Blockly.Blocks['panya_turn'] = {
  init: function() {
    this.appendDummyInput()
        .appendTitle("turn")
        .appendTitle(new Blockly.FieldDropdown([["left", "L"], ["right", "R"]]), "latdir");
    this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Turn the PanyaBot in the given direction.');
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
  }
};

Blockly.Blocks['panya_stop'] = {
  init: function() {
    this.appendDummyInput()
        .appendTitle("Stop")
    this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Stop the PanyaBot');
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
  }
};

Blockly.Blocks['panya_set_speed'] = {
  init: function() {
    this.appendValueInput("SPEED")
        .setCheck("Number")
        .appendTitle("set speed to");
    this.setInputsInline(true);
	this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Set the desired speed for the PanyaBot');
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
  }
};
