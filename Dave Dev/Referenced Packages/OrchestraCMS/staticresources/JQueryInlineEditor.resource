/**
 * @preserve JQueryInlineEditor.js - jQuery UI Plugin for a common generic inline editor component used within Orchestra.
 *
 * Copyright (c) 2010, 2011 - Stantive Technologies Group (http://www.stantive.com)
 * All Rights Reserved.
 * NOTE: THIS FILE IS GENERATED, PLEASE MODIFY THE FILE LOCATED IN "other-src/web/ocmsJS/" DIRECTORY.
 */
$(document).data('cms_JQueryInlineEditor-LOADED', true);

(function($) {

    /**
     * This basically will place an edit box into the wrapped object and upon 'click' allow the user to edit the
     * text.  It will have a save type button and it will call the users defined 'onOK' callback on save, if
     * false is returned from save then it is like cancelling the edit, ie: It was 'NOT' saved.
     *
     * Usage:
     * $('...').ocmsInlineEditor( {
     *     saveText:String        The text to use on the save button, defaults to no text.
     *   , saveTip:String         The tooltip text to be used on the save button
     *   , editTip:String         The tooltip text to be used on the editable element itself
     *   , editingTip:String      The tooltip text to be used on the editable element itself, when we are editing the element
     *   , onOK:Function          The callback that is called when the user has finished editing and has opted to 'save' the text.
     *                            returning false will cancel the edit, true means make the change.
     *   , enterSubmits:Boolean   Whether or not hitting the enter key during editing acts like hitting the save button. Default [false]
     *   , placeHolder:String     Place holder text, that is placed into the element to be editable, but is just a placeholder like 'Click to edit this'
     * });
     */
    $.widget("ui.ocmsInlineEditor", {

        /**
         * Called to create the inline editor component.
         */
        _create: function() {
            var self = this;
            var o = self.options;
            self._bUsingPlaceHolder = false;
            var editableElement = $(self.element[0]);
            if(!editableElement.hasClass('ocms-editable'))
                editableElement.addClass('ocms-editable');
            var text = $.trim(editableElement.text());
            if(text === undefined || text === '')
            {
                if(o.placeHolder != null)
                {
                    self._bUsingPlaceHolder = true;
                    var placeholderHtml = '<span class="ocms-inline-editor-placeholder">'+ o.placeHolder +'</span>';
                    editableElement.append(placeholderHtml);
                }
            }
            self._value(text);
            self._setupBehaviours();
            return this;
        },

        /**
         * Sets up the behaviours for the editable element.
         */
        _setupBehaviours: function() {
            var self = this;
            var editableElement = $(self.element[0]);
            if(self.options.editTip != null)
            {
                editableElement.attr('title', self.options.editTip);
            }

            editableElement.hover(
                    function () {
                        editableElement.addClass('ocms-inline-editor-hover');
                    },
                    function () {
                        editableElement.removeClass('ocms-inline-editor-hover');
                    });
            editableElement.bind('mousedown', function(evt) {
                evt.stopImmediatePropagation();
            });
            editableElement.bind('mouseup', function(evt) {
                evt.stopImmediatePropagation();
            });
            editableElement.bind('click', function(evt) {
                evt.stopImmediatePropagation();
                self._resetBehaviours();
                self._installEditor();
            });

        },

        /**
         * Resets the behaviours on the editable element, we simply remove the hover classes and unbind our
         * handlers.
         */
        _resetBehaviours: function() {
            var editableElement = $(this.element[0]);
            editableElement.removeClass('ocms-inline-editor-hover').unbind('click').unbind('mousedown').unbind('mouseenter').unbind('mouseleave');
        },

        /**
         * Installs the editor into the editable element.  We create an input and save button and place it into the
         * editable element.  We don't worry as we've already saved the editable elements contents by calling this._value(elements_contents);
         */
        _installEditor: function() {
            var self = this;
            var o = self.options;
            var editableElement = $(self.element[0]);

            editableElement.attr('title', o.editingTip);
            editableElement.html($('<input type="text" value="' + self._value() + '"/><img title="'+o.saveTip+'" alt="'+o.saveText+'" src="' + $(document).data('clear_dot_image') + '" class="ocms-inline-editor-icon-save">'));
            var inlineEditBox = editableElement.find('input');
            var saveButton = editableElement.find('img');

            // -- if option to save on <enter> key pressed, then setup the handler, again if save reset.
            if(o.enterSubmits)
            {
                inlineEditBox.keypress(function(e) {
                    if ($.orchestracmsUtil.isEventEnterKey(e)) {
                        if(self._saveValue(inlineEditBox.val(), inlineEditBox))
                        {
                            self._resetView();
                            self._setupBehaviours();
                        }
                    }
                });

            }
            // -- Save button saves the value, if successful, reset
            saveButton.click(function(evt){
                evt.stopImmediatePropagation();
                var theValue = inlineEditBox.val();
                if(self._saveValue(theValue, inlineEditBox))
                {
                    self._resetView();
                    self._setupBehaviours();
                }
            });

            // -- Put the onblur event into a timer because clicking the save button actually
            //    fires the blur event first and thus cancels the edit.
            inlineEditBox.bind('blur', function() { $.logWarn("BLURRED {0}", "InlineEditor");
                if (self.timer) {
                    window.clearTimeout(self.timer);
                    self.timer = null;
                }
                self.timer = window.setTimeout(function() {
                    self._resetView();
                    self._setupBehaviours();
                }, 200);

            });
            // -- Focus the input
            inlineEditBox.focus();

        },

        /**
         * Called by the handlers to save the given value.  We don't do any saving, but rather delegate that
         * to a callback defined in options.onSave.  If onSave returns true we save the value as the editable
         * components new value.
         * @param sValue The value to set element to.
         * @param inlineEditBox The input control handling the user input.
         * @return true if save was successful, false otherwise.
         */
        _saveValue: function(sValue, inlineEditBox) {
            var self = this;
            var o = self.options;
            // -- First clear the timer if there is any set.
            if (self.timer) {
                window.clearTimeout(self.timer);
                self.timer = null;
            }
            // -- Check if changed
            if(sValue !== self._value())
            {
                // -- Call the callback to do the saving.....
                if ($.isFunction(o.onSave))
                {
                    if(o.onSave(self, sValue, inlineEditBox) !== false)
                    {
                        self._value(sValue);
                        return true;
                    }
                }
            }
            else
            {   // -- Show message?
                return true;
            }
            return false;

        },

        /**
         * This method will store the given value as the editable components value.  If no value given then
         *  nothing is saved and the already saved value is returned.
         * @param value The new value to set the editable components value to, can be null
         * @return The saved value of the editable component.
         */
        _value : function (value) {
            var self = $(this);
            if(value != null || value != undefined)
            {
                if(self._bUsingPlaceHolder)
                	$.orchestracmsUtil.setDataInfo(self, '');
                else
                	$.orchestracmsUtil.setDataInfo(self, value);
            }
            return $.orchestracmsUtil.getDataInfo(self);
        },

        /**
         * Resets the view of the editable component to its original state, with the saved value.
         */
        _resetView : function () {
            var self = this;
            var element = self._value();
            $(this.element[0]).html(element);
        },

        options: {
            version: 0.1
            /* The text to be used on the save button */
            ,   saveText: ''
            /* The tooltip text to be used on the save button */
            ,   saveTip: ''
            /* The tooltip text to be used on the editable element itself */
            ,   editTip: null
            /* The tooltip text to be used on the editable element itself, when we are editing the element */
            ,   editingTip: ''
            /* The callback that is called when the user has finished editing and has opted to 'save' the text, return false to have the edit cancelled.
             *  onSave(THIS_OBJECT, VALUE-TO-BE-SAVED, INLINE-EDIT-CONTROL); */
            ,   onSave: null
            /* Whether or not hitting the enter key during editing acts like hitting the save button. Default [false] */
            ,   enterSubmits: false
            /* Place holder text, that is placed into the element to be editable, but is just a placeholder for new 'Click to edit this' */
            ,   placeHolder: null
        }

    });

})(jQuery);
