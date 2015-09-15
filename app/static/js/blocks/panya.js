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


Blockly.Blocks['panya_move'] = {
    init: function() {
        this.setHelpUrl('http://www.example.com/');
        this.setColour(160);
        this.appendDummyInput()
            .appendTitle("move")
            .appendTitle(new Blockly.FieldDropdown([["forward", "forward"], ["forward", "forward"]]), "Direction");
        this.setInputsInline(true);
        this.setPreviousStatement(true);
        this.setNextStatement(true);
        this.setTooltip('Give the time for which you want panyabot to move forward');
  }
};

Blockly.Blocks['panya_turn'] = {
  init: function() {
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
    this.appendDummyInput()
        .appendTitle("turn")
        .appendTitle(new Blockly.FieldDropdown([["left ⟲", "left"], ["right ⟳", "right"]]), "direction");
    this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Turn the PanyaBot in the given direction.');
  }
};

Blockly.Blocks['panya_stop'] = {
  init: function() {
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
    this.appendDummyInput()
        .appendTitle("Stop");
    this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Stop the PanyaBot');
  }
};

Blockly.Blocks['panya_set_speed'] = {
  init: function() {
    this.setHelpUrl('http://www.example.com/');
    this.setColour(160);
    this.appendValueInput("SPEED")
        .setCheck("Number")
        .appendTitle("set speed to");
    this.setInputsInline(true);
	this.setPreviousStatement(true);
    this.setNextStatement(true);
    this.setTooltip('Set the desired speed for the PanyaBot');
  }
};
