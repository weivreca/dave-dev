/**
 * @deprecated TableEditor.resource
 * Copyright (c) 2010, 2011 - Stantive Technologies Group (http://www.stantive.com)
 * All Rights Reserved.
 * NOTE: THIS FILE IS NOW LOCATED IN OrchestraCMSUI ZIPPED RESOURCE.
 */
(function($){
	$.widget("ui.table_editor", {

		_create: function() {

			var self = this;
			var el = $(this.element[0]);
			var table;
			var body;
			self.cellmap = {};
			self.disabled = self.options.disabled;

			//make sure the defaults are set properly
			if(self.options.defaultCellHeight == '' || self.options.defaultCellHeight == null || self.options.defaultCellHeight == undefined || self.options.defaultCellHeight == 0) {
				self.options.defaultCellHeight = 30;
			}

			if(self.options.defaultCellWidth == '' || self.options.defaultCellWidth == null || self.options.defaultCellWidth == undefined || self.options.defaultCellWidth == 0) {
				self.options.defaultCellWidth = 250;
			}

			if(self.options.defaultCellPadding == '' || self.options.defaultCellPadding == null || self.options.defaultCellPadding == undefined || self.options.defaultCellPadding == 0) {
				self.options.defaultCellPadding = 5;
			}

			//setup the table and container
			if(el.children('table').length > 0){
				table = $(el.children('table')[0]);
				body = table.children('tbody');
				self.rows = body.children('tr').length;
				self.cols = body.children('tr:first').children('td').length;
				if(table.width() <= 0) {
					table.css('width', self.options.defaultTableWidth);
				}

			}else{
				//add a container if being applied directly to a table
				if(el.nodeName == 'table') {
					table = el;
					el = $('<div></div>');
					table.before(el);
					el.append(table);
					if(table.width() <= 0) {
						table.css('width', self.options.defaultTableWidth);
					}
					body = table.children('tbody');
				} else {
					table = $('<table class="ui-widget"><thead></thead><tbody></tbody><tfoot></tfoot></table>');
					body = table.find('tbody');
					table.css('width', self.options.defaultTableWidth);
					el.append(table);
				}

				self.rows = body.children('tr').length;
				self.cols = body.children('td').length;
			}

			if(self.rows == 0) {
				for(var i=0; i < self.options.defaultRows; ++ i) {
					var tr = $('<tr></tr>');
					for(var j=0; j < self.options.defaultColumns; ++j) {
						tr.append(self._createCell(i,j));
					}
					body.append(tr);
				}

				self.rows = self.options.defaultRows;
				self.cols = self.options.defaultColumns;
			}

			self.container = el;
			self.table = table;

			//set table margins so that the scroll accounts for the right click menu
			self.table.css({'margin-bottom': '200px'});

			if(self.options.debug) {
				var serializeBtn =  $('<button id="serialize">Serialize</button>');
				serializeBtn.bind('click', function(){
					alert(self.serialize());
				});

				el.prepend(serializeBtn);
			}


			table.addClass('ui-edit-table');

			//build the cell map
			self.tbody = body;
			var rows = self.tbody.children('tr');

			var numrows = rows.length;
			var numcols = 0;

			var rowspanMemory = {};
			var rowspanColspanMemory = {};
			var setupcells = new Array();

			if (rows.length > 0) {
				for (var i = 0; i < rows.length; ++i) {
					var cells = $(rows[i]).children('td');

					if (cells.length > 0) {
						for (var j = 0; j < cells.length; ++j) {
							var colspan = parseInt($(cells[j]).attr('colspan'));
							colspan = isNaN(colspan) ? 1 : colspan;
							numcols += colspan;
						}
						break;
					}
				}
			}

			for(var j=0; j < numcols; ++j) {
				rowspanMemory[j] = 0;
				rowspanColspanMemory[j] = 0;
			}

			for(var i=0; i < rows.length; ++i) {

				var actualcolposition = 0;
				var cols = $(rows[i]).children('td');

				for(var j=0; j < cols.length; ++j){

					var cell = $(cols[j]);
					setupcells.push(cell);

					while(rowspanMemory[actualcolposition] > 0) {
						actualcolposition += rowspanColspanMemory[actualcolposition];
					}

					cell.data('row', i);
					cell.data('col', actualcolposition);

					if(cell.width() <= 0) {
						cell.css('width', self.options.defaultCellWidth);
					}

					if(cell.height() <= 0) {
						cell.css('height', self.options.defaultCellHeight);
					}

					var rspan = parseInt(cell.attr('rowspan'));
					var cspan = parseInt(cell.attr('colspan'));

					cspan = isNaN(cspan) ? 1 : cspan;
					rspan = isNaN(rspan) ? 1 : rspan;

					for(k = i; k < i+rspan; ++k) {
						for(l = actualcolposition; l < actualcolposition+cspan; ++l) {
							if (self.cellmap[k + ',' + l] === undefined) {
								self.cellmap[k + ',' + l] = cell;
							}
						}
					}


					if(rspan > 1) {
						rowspanMemory[actualcolposition] = rspan;
						rowspanColspanMemory[actualcolposition] = cspan;
					}
					actualcolposition += cspan;
				}

				//decrement rowspan counters
				for (var k = 0; k < numcols; ++k) {
					if (rowspanMemory[k] > 0) {
						--rowspanMemory[k];
					}
				}
			}

			self.rows = numrows;
			self.cols = numcols;

			self.table = table;

			if($.isFunction(self.options.afterCellsAdded)){
				self.options.afterCellsAdded(setupcells);
			}

			self._calculateTableWidth();

			if (self.options.fitToCell != null) {
				for (var q = 0; q < rows.length; ++q) {
					self.updateFitToCellForRow(q);
				}
			}

			//setup interactions if the table is not disabled
			if (!self.disabled) {
				table.selectable({
					tolerance: 'touch',
					filter: 'td',
					autoRefresh: false,
					start: function(event, ui) {
						self.refresh();
					},

					stop: function(event, ui) {

						var selected = $(this).find('.ui-selected');
						var cellmap = self.cellmap;
						var firstcell = $(selected[0]);

						var rowspan = parseInt(firstcell.attr('rowspan'));
						var colspan = parseInt(firstcell.attr('colspan'));

						if(isNaN(rowspan)) {
							rowspan = 1;
						}

						if(isNaN(colspan)) {
							colspan = 1;
						}

						var top = firstcell.data('row');
						var bottom = top+rowspan-1;
						var left = firstcell.data('col');
						var right = left+colspan-1;

						//find the edges
						for(var i=1; i<selected.length; ++i) {

							var cell = $(selected[i]);


							var row = cell.data('row');
							var col = cell.data('col');
							var rowspan = parseInt(cell.attr('rowspan'));
							var colspan = parseInt(cell.attr('colspan'));

							if(isNaN(rowspan)) {
								rowspan = 1;
							}

							if(isNaN(colspan)) {
								colspan = 1;
							}

							if(row < top) {
								top = row;
							}

							if(col < left) {
								left = col;
							}

							if(row+rowspan-1 > bottom) {
								bottom = row+rowspan-1;
							}

							if(col+colspan-1 > right) {
								right = col+colspan-1;
							}

						}

						//make sure everything inbetween is selected

						for(var i=top; i <= bottom; ++i) {
							for (var j=left; j <= right; ++j) {
								if (cellmap[i + ',' + j] === undefined) {
									alert(i+','+j);
								} else {
									cellmap[i + ',' + j].addClass('ui-selected');
								}
							}
						}

					}
				});



				if(self.options.debug) {
					table.before('<div><span>DD Value: </span><span id="dragDrop"></span></div>');
				}

				table.children('tbody').droppable({
					accept: self.options.accept,
					tolerance: 'pointer',
					over: function(event, ui){
					},

					out: function(event, ui){
						$(this).find('.ui-table-active-cell').removeClass('ui-table-active-cell');
					},

					activate: function(event, ui){
						self.refreshPositions();
						var dropzone = $(this);
						var x = event.pageX;
						var y = event.pageY;
						var hovering = self._findCell(x, y);
						if (hovering != null) {
							hovering.addClass('ui-table-active-cell');
						}

						ui.draggable.bind('drag', function(event, ui){

							var x = event.pageX;
							var y = event.pageY;
							var hovering = self._findCell(x, y);

							if (hovering != null) {
								if (!hovering.hasClass('ui-table-active-cell')) {
									dropzone.find('.ui-table-active-cell').removeClass('ui-table-active-cell');
									hovering.addClass('ui-table-active-cell');
								}
							}
						});

					},

					drop: function(event, ui){

						$(this).find('.ui-table-active-cell').removeClass('ui-table-active-cell');

						var x = event.pageX;
						var y = event.pageY;

						var droppedOn = self._findCell(x, y);
						if ($.isFunction(self.options.received)) {
							self.options.received(event, ui, droppedOn, self);
						}
					}

				});


				self._setupRightClickContextMenu();

			}

		if(self.options.debug) {
			self._debugCells();
		}

		self.refresh();
		self.setupTableDraggables(self.table.find('.tableitem'))

	},

	_setupRightClickContextMenu: function() {

		var self = this;
		var el = self.container;
		var table = self.table;
		var body = self.tbody;

		var documentClickHandler = function(e) {
			if (e.button == 0) {
				body.find('.ui-selected').removeClass('ui-selected');
				contextMenu.fadeOut('fast');
			}
		}

		var contextMenu = $('<ul class="contextMenu">'+
						      '<li class="add-row-before"><a href="#"><nobr>Insert Row Above</nobr></a></li>'+
							  '<li class="add-row-after"><a href="#"><nobr>Insert Row Below</nobr></a></li>'+
							  '<li class="add-column-before"><a href="#"><nobr>Insert Column Before</nobr></a></li>'+
							  '<li class="add-column-after"><a href="#"><nobr>Insert Column After</nobr></a></li>'+
							  '<li class="separator"></li>'+
							  '<li class="merge"><a href="#"><nobr>Merge</nobr></a></li>'+
							  '<li class="split"><a href="#"><nobr>Split</nobr></a></li>'+
							  '<li class="separator"></li>'+
							  '<li class="delete-row"><a href="#"><nobr>Delete Row</nobr></a></li>'+
							  '<li class="delete-column"><a href="#"><nobr>Delete Column</nobr></a></li>'+
							  '<li class="separator"></li>'+
							  '<li class="edit-cell-column"><a href="#"><nobr>Edit Cell Properties</nobr></a></li>'+
							  '<li class="separator"></li>'+
							  '<li class="edit-table-properties"><a href="#"><nobr>Edit Table Properties</nobr></a></li>'+
						  '</ul>');

		contextMenu.find('.edit-table-properties').bind('click', function(e){
				self.launchPropertiesDialog();
		});

		contextMenu.find('.delete-row').bind('click', function(e){
			e.stopPropagation();

			var cells = body.find('.ui-selected');
			if (cells.length > 0) {
				var cell = $(cells[0]);
				self.removeRows(1, cell, true);
				contextMenu.hide();
			}
			return false;
		});

		contextMenu.find('.add-row-after').bind('click', function(){
			var cell = $(body.find('.ui-selected')[0]);
			self.addRows(1, cell, 'after', true);
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.add-row-before').bind('click', function(){
			var cell = $(body.find('.ui-selected')[0]);
			self.addRows(1, cell, 'before', true);
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.delete-column').bind('click', function(){
			var cell = $(body.find('.ui-selected')[0]);
			self.removeColumns(1, cell, true);
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.add-column-after').bind('click', function(){
			var cell = $(body.find('.ui-selected')[0]);
			self.addColumns(1, cell, 'after', true);
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.add-column-before').bind('click', function(){
			var cell = $(body.find('.ui-selected')[0]);
			self.addColumns(1, cell, 'before', true);
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.merge').bind('click', function(){
			self.mergeSelectedCells();
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.split').bind('click', function(){
			self.breakApartSelected();
			contextMenu.hide();
			return false;
		});

		contextMenu.find('.edit-cell-column').bind('click', function(){

			var cells = body.find('td.ui-selected');
			var cell = $(cells[0]);
			var textalign = cell.css('text-align');
			var verticalalign = cell.css('vertical-align');
			var padding = '';

			var cell_width = null;
			var cell_height = null;

			if(cell != null) {
				var general = parseInt(cell.css('padding'));
				if(isNaN(general)) {
					general = parseInt(cell.css('padding-top'));
				}

				if(!isNaN(general)) {
					padding = general;
				}

				var style = cell.attr('style')+' ';
				var width_patt = /width\s*:\s*(\d+)\s*px/i;
				var height_patt = /height\s*:\s*(\d+)\s*px/i

				var width_matches = style.match(width_patt);
				var height_matches = style.match(height_patt);

				if(width_matches != null) {
					cell_width = parseInt(width_matches[1]);
				} else {
					cell_width = cell.width();
				}

				if(height_matches != null) {
					cell_height = parseInt(height_matches[1]);
				} else {
					cell_height = cell.height();
				}
			}

			var cellPropertiesDialog = $('<div title="Cell Properties">'+
								'<div class="cell-msg" style="display:none; padding: 3px; color: #990000;"></div>'+
								'<table>'+
									'<tr>'+
										'<td>Cell Width</td>'+
										'<td><input type="text" id="cellwidth" name="cellwidth" size="6" value="'+(cell_width == null || isNaN(cell_width) ? '' : cell_width)+'" /></td>'+
										'<td>Apply to Column</td>'+
										'<td><input name="applyColumn" type="checkbox" value="true" /></td>'+
									'</tr>'+
									'<tr>'+
										'<td>Cell Height</td>'+
										'<td><input type="text" id="cellheight" name="cellheight" size="6" value="'+(cell_height == null || isNaN(cell_height) ? '' : cell_height)+'" /></td>'+
										'<td>Apply to Row</td>'+
										'<td><input name="applyRow" type="checkbox" value="true" /></td>'+
									'</tr>'+
									'<tr>'+
										'<td>Cell Padding</td>'+
										'<td colspan="3" style="text-align: left;"><input type="text" id="cellpadding" name="cellpadding" size="6" value="'+padding+'" /></td>'+
									'</tr>'+
									'<tr>'+
										'<td>Align</td>'+
										'<td colspan="3" style="text-align: left;"><select id="alignment"><option value="">Default</option><option value="left" '+(textalign == 'left' ? 'selected' : '')+' >Left</option><option value="center" '+(textalign == 'center' ? 'selected' : '')+' >Center</option><option value="right" '+(textalign == 'right' ? 'selected' : '')+' >Right</option></select></td>'+
									'</tr>'+
									'<tr>'+
										'<td>Vertical Align</td>'+
										'<td colspan="3" style="text-align: left;"><select id="vertical-alignment"><option value="">Default</option><option value="top" '+(verticalalign == 'top' ? 'selected' : '')+' >Top</option><option value="middle" '+(verticalalign == 'middle' ? 'selected' : '')+' >Middle</option><option value="bottom" '+(verticalalign == 'bottom' ? 'selected' : '')+' >Bottom</option></select></td>'+
									'</tr>'+
								'</table>'+
							'</div>');

			if(cells.length > 1) {
				cellPropertiesDialog.find('table').append('<tr>'+
										'<td colspan="3" style="text-align: left;"><input type="checkbox" name="applyAll" id="applyAll" value="applyAll" />&nbsp;Apply to all selected cells</td>'+
									'</tr>');
			}

			cellPropertiesDialog.dialog({
				modal:true,
				open: function() {

					$(document).unbind('click', documentClickHandler);

					var rowspan = null;
					var colspan = null;
					if (cell != null) {
						rowspan = parseInt(cell.attr('rowspan'));
						colspan = parseInt(cell.attr('colspan'));
					}

					rowspan = isNaN(rowspan) ? 1 : rowspan;
					coslpan = isNaN(colspan) ? 1 : rowspan;

					if(rowspan > 1 || cells.length > 1) {
						$(this).find('input:checkbox[name=applyRow]').attr('disabled', true);
					}

					if(colspan > 1 || cells.length > 1) {
						$(this).find('input:checkbox[name=applyColumn]').attr('disabled', true);
					}

				},

				buttons: {
					Save: function(){

						var int_pattern = /^[0-9]+$/;
						var has_errors = false;
						var errors = '';

						var cellwidth = $(this).find('#cellwidth').val();
						if(!int_pattern.test(cellwidth)){
							cellwidth = '0';
							has_errors = true;
							errors = errors + 'Cell width must be an integer<br />';
						}
						var cellheight = $(this).find('#cellheight').val();
						if(!int_pattern.test(cellheight)){
							cellheight = '0';
							has_errors = true;
							errors = errors +  'Cell height must be an integer<br />';
						}
						var align = $(this).find('#alignment').val();
						var valign = $(this).find('#vertical-alignment').val();
						var cellpadding = $(this).find('#cellpadding').val();
						if(!int_pattern.test(cellpadding)){
							cellpadding = '0';
							has_errors = true;
							errors = errors +  'Cell padding must be an integer<br />';
						}

						if(has_errors){
							$(this).find('.cell-msg').html(errors);
							$(this).find('.cell-msg').show();
							return false;
						}else{
							$(this).find('.cell-msg').empty();
							$(this).find('.cell-msg').hide();
						}

						if(cells.length == 1 || !$(this).find('#applyAll').attr('checked')) {
							cell.css({
								"height": cellheight+'px',
								"width": cellwidth+'px',
								"padding": cellpadding+'px',
								"text-align": align,
								"vertical-align": valign
							});
						} else {
							for (var i = 0; i < cells.length; ++i) {
								$(cells[i]).css({
									"height": cellheight+'px',
									"width": cellwidth+'px',
									"padding": cellpadding+'px',
									"text-align": align,
									"vertical-align": valign
								});
							}
						}

						if($(this).find('input:checkbox[name=applyColumn]:checked').val() == 'true') {
							self._setNewColumnWidth(cell, cellwidth);
						}

						if($(this).find('input:checkbox[name=applyRow]:checked').val() == 'true') {
							self._setNewRowHeight(cell, cellheight);
						}

						if (cell == null) {
							self._calculateTableWidth($(cells[0]).data('row'));
						} else {
							self._calculateTableWidth(cell.data('row'));
						}

						if($.isFunction(self.options['saveProperties'])) {
							self.options['saveProperties']({'cols':self.cols, 'rows':self.rows, 'cellwidth': self.options.defaultCellWidth, 'cellheight': self.options.defaultCellHeight, 'table': self.serialize()});
						}

						self.table.selectable('refresh');

						$(this).dialog('destroy');

						$(document).bind('click', documentClickHandler);
						return false;
					},

					Cancel: function(){

						$(document).bind('click', documentClickHandler);
						$(this).dialog('destroy');
						return false;
					}

				},

				close: function(event, ui) {
					$(document).bind('click', documentClickHandler);
					$(this).dialog('destroy');
					return false;
				}

			});

			contextMenu.hide();
			return false;

		});

		contextMenu.hide();
		el.append(contextMenu);

		body.click(function(e) {
			e.stopPropagation();
			if (e.button == 0) {
				contextMenu.fadeOut('fast');
			}
		});

		$(document).click(documentClickHandler);

		var evt;
		body.bind('mousedown', function(e) {
			evt = e;
		});

		body.bind('mouseup', function(e){
			var srcElement = $(this);

			if (evt !== undefined) {
				if (evt.button == 2) {

					//find the cell that triggered the event

					var x = evt.pageX;
					var y = evt.pageY;

					self.refresh();

					var selectedCell = self._findCell(x, y);

					if (selectedCell.hasClass('ui-selected')) {
					//if it's already selected it could be a range
					} else {
						body.find('.ui-selected').removeClass('ui-selected');
						selectedCell.addClass('ui-selected');
					}
					contextMenu.css({
						top: y,
						left: x
					}).fadeIn('fast');

					// Disable text selection

					if ($.browser.mozilla) {
						contextMenu.css({
							'MozUserSelect': 'none'
						});

					} else if ($.browser.msie) {

						contextMenu.bind('selectstart.disableTextSelect', function(){
							return false;
						});

					} else {

						contextMenu.bind('mousedown.disableTextSelect', function(){
							return false;
						});
					}

					// Disable browser context menu (requires both selectors to work in IE/Safari + FF/Chrome)
				}
			}
		});


		body.bind('contextmenu', function() { return false; });
		contextMenu.bind('contextmenu', function() { return false; });

		contextMenu.find('a').hover(
			function(){
					contextMenu.find('li.hover').removeClass('hover');
					$(this).parent().addClass('hover');
			},
			function() {
				$(contextMenu).find('li.hover').removeClass('hover');
			}
		);

	},

	launchPropertiesDialog: function() {

			//launch the properties dialog
			var propertiesDialog;
			var self = this;
			if($('body').find('#tablePropertiesDialog').length > 0) {
				propertiesDialog = $($('body').find('#tablePropertiesDialog')[0]);
			} else {
				propertiesDialog = $('<div title="Table Properties" id="tablePropertiesDialog" style="display: none;">'+
									    '<div class="cell-msg" style="display:none; padding: 3px; color: #990000;"></div>'+
										'<table class="inputForm">'+
											'<tr>'+
												'<td>Default Cell Width</td>'+
												'<td><input id="cellwidth" type="text" size="6" value="'+self.options.defaultCellWidth+'" /></td>'+
											'</tr>'+
											'<tr>'+
												'<td>Default Cell Height</td>'+
												'<td><input id="cellheight" type="text" size="6" value="'+(self.options.defaultCellHeight == null ? '' : self.options.defaultCellHeight)+'" /></td>'+
											'</tr>'+
											'<tr>'+
												'<td>Default Cell Padding</td>'+
												'<td><input id="cellpadding" type="text" size="6" value="'+(self.options.defaultCellPadding == null ? '' : self.options.defaultCellPadding)+'" /></td>'+
											'</tr>'+
											'<tr>'+
												'<td>Rows</td>'+
												'<td><input id="rows" type="text" size="6" value="'+self.rows+'" /></td>'+
											'</tr>'+
											'<tr>'+
												'<td>Columns</td>'+
												'<td><input id="cols" type="text" size="6" value="'+self.cols+'" /></td>'+
											'</tr>'+
										'</table>'+
									'</div>');
				$('body').append(propertiesDialog);
			}

			propertiesDialog.dialog({
				modal: true,
				buttons: {
					Save: function() {

						var int_pattern = /^[0-9]+$/;
						var has_errors = false;
						var errors = '';

						var saveProperties = self.options.saveProperties;
						var cols = $(this).find('#cols').val();
						if(!int_pattern.test(cols)){
							cols = '0';
							has_errors = true;
							errors = errors + 'Columns must be an integer<br />';
						}else{
							cols = parseInt(cols);
						}

						var rows = $(this).find('#rows').val();
						if(!int_pattern.test(rows)){
							rows = '0';
							has_errors = true;
							errors = errors + 'Rows must be an integer<br />';
						}else{
							rows = parseInt(rows);
						}

						var cellwidth = $(this).find('#cellwidth').val();
						if(!int_pattern.test(cellwidth)){
							cellwidth = '0';
							has_errors = true;
							errors = errors + 'Default Cell Width must be an integer<br />';
						}else{
							cellwidth = parseInt(cellwidth);
						}

						var cellheight = $(this).find('#cellheight').val();

						var cellheight = $(this).find('#cellheight').val();
						if(!int_pattern.test(cellheight)){
							cellheight = '0';
							has_errors = true;
							errors = errors + 'Default Cell Height must be an integer<br />';
						}else{
							cellheight = parseInt(cellheight);
						}

						var cellpadding = $(this).find('#cellpadding').val();

						var cellpadding = $(this).find('#cellpadding').val();
						if(!int_pattern.test(cellpadding)){
							cellpadding = '0';
							has_errors = true;
							errors = errors + 'Default Cell Padding must be an integer<br />';
						}else{
							cellpadding = parseInt(cellpadding);
						}

						if(has_errors){
							$(this).find('.cell-msg').html(errors);
							$(this).find('.cell-msg').show();
							return false;
						}else{
							$(this).find('.cell-msg').empty();
							$(this).find('.cell-msg').hide();
						}

						self._setOption('defaultCellWidth', cellwidth);
						self._setOption('defaultCellHeight', cellheight);
						self._setOption('defaultCellPadding', cellpadding);

						if(!isNaN(cols) && !isNaN(rows)) {

							self.setNbRowsAndColumns(rows, cols);

							var rows = self.table.children('tbody').children('tr');

							for(var i=0; i < rows.length; ++i) {
								cells = $(rows[i]).children('td');
								for(var j=0; j<cells.length; ++j) {
									$(cells[j]).css({
										"height": cellheight+'px',
										"width": cellwidth+'px',
										"padding": cellpadding+'px'
									});
								}
							}

							if($.isFunction(saveProperties)) {
								saveProperties({'cols':self.cols, 'rows':self.rows, 'cellwidth': cellwidth, 'cellheight': cellheight, 'cellpadding': cellpadding, 'table': self.serialize()});
							}

							self.refreshPositions();
						}

						$(this).dialog('destroy');
						self._calculateTableWidth();
						propertiesDialog.remove();
					},

					Cancel: function() {
						$(this).dialog('destroy');
						propertiesDialog.remove();
					}
				}
			});

		},

		setNbRowsAndColumns: function(newrows, newcolumns){

			var self = this;
			var table = self.table;
			var cellmap = self.cellmap;
			var body = self.tbody;
			var afterCellsAdded = self.options.afterCellsAdded;
			var afterCellsRemoved = self.options.afterCellsRemoved;

			var addedCells = new Array();
			var deletedCells = new Array();

			var nbcolumns = self.cols;
			var nbrows = self.rows;

			//rows should always be added first since columns are children of rows in html
			//columns should always be deleted first since columns are children of rows

			if(nbrows < newrows) {
				var nbnew = newrows - nbrows;
				var returnedCells;
				if (nbrows > 0) {
					returnedCells = self.addRows(nbnew, cellmap[(nbrows - 1) + ',' + 0], 'after', false);
				} else {
					returnedCells = self.addRows(nbnew, null, 'after', false);
				}

				for (var i = 0; i < returnedCells.length; ++i) {
					addedCells.push(returnedCells[i]);
				}

			}

			if(nbrows > newrows) {
				var nbremove = nbrows - newrows;
				var removedCells = self.removeRows(nbremove, cellmap[(nbrows-nbremove)+','+0], false);
				for (var i = 0; i < removedCells.length; ++i) {
					deletedCells.push(removedCells[i]);
				}
			}

			if(nbcolumns > newcolumns) {
				var nbremove = nbcolumns - newcolumns;
				var removedCells = self.removeColumns(nbremove, cellmap[0+','+(nbcolumns - nbremove)], false);

				for (var i = 0; i < removedCells.length; ++i) {
					deletedCells.push(removedCells[i]);
				}
			}

			if(nbcolumns < newcolumns) {
				var nbnew = newcolumns - nbcolumns;
				var returnedCells;
				if (nbcolumns > 0) {
					returnedCells = self.addColumns(nbnew, cellmap[0 + ',' + (nbcolumns - 1)], 'after', false);
				} else {
					returnedCells = self.addColumns(nbnew, null, 'after', false);
				}

				for (var i = 0; i < returnedCells.length; ++i) {
					addedCells.push(returnedCells[i]);
				}
			}

			if(addedCells.length > 0) {
				if($.isFunction(afterCellsAdded)) {
					afterCellsAdded(addedCells);
				}
			}

			if(deletedCells.length > 0) {
				if($.isFunction(afterCellsRemoved)) {
					afterCellsRemoved(deletedCells);
				}
			}

			self.cols = newcolumns;
			self.rows = newrows;
			self.refresh();
		},


		addColumns: function(count, cell, position, executeCallbacks) {

			var self = this;
			var nbcols = self.cols;
			var nbrows = self.rows;
			var table = self.table;
			var body = self.tbody;
			var cellmap = self.cellmap;
			var saveProperties = self.options['saveProperties'];
			var afterCellsAdded = self.options['afterCellsAdded'];
			var afterCellsUpdated = self.options['afterCellsUpdated'];
			var callbacks = executeCallbacks ? true: executeCallbacks;

			var column = 0;
			var colspan = 1;
			var rows = body.children('tr');
			var newcells = new Array();
			var updatedcells = new Array();

			var start = 0;

			if (cell != null) {
				column = cell.data('col');
				colspan = parseInt(cell.attr('colspan'));
				colspan = isNaN(colspan) ? 1 : colspan;

				if (self._checkForMergedCells(position, 'col', cell)) {
					self._errorNotify("Columns can't be added to merged cells");
					return newcells;
				}

				table.css('width', 'auto');
				start = position == 'after' ? column + colspan : column;
			}


			//update after cells;
			if(cell != null) {

				for (var j = nbcols - 1; j >= start; --j) {

					for (var i = 0; i < nbrows; ++i) {

						var updatecell = cellmap[i + ',' + j];

						if (i == updatecell.data('row') && j == updatecell.data('col')) {
							var newcol = updatecell.data('col') + count;
							var rowspan = parseInt(updatecell.attr('rowspan'));
							var colspan = parseInt(updatecell.attr('colspan'));

							rowspan = isNaN(rowspan) ? 1 : rowspan;
							colspan = isNaN(colspan) ? 1 : colspan;

							updatecell.data('col', newcol);

							for (var k = i; k < i + rowspan; ++k) {
								for (var l = newcol; l < newcol + colspan; ++l) {
									cellmap[k + ',' + l] = updatecell;
								}
							}
							updatedcells.push(updatecell)
						}
					}

				}
			}

			for (var i = 0; i < nbrows; ++i) {

				var current = null;
				var startreference = position == 'after' ? column + colspan - 1 : column - 1;
				var referencerow = $(rows[i]);

				if (cell != null) {
					if (startreference >= 0) {
						current = cellmap[i + ',' + startreference];
						var current_rowspan = current.attr('rowspan');
						current_rowspan = isNaN(current_rowspan) ? 1 : current_rowspan;

						//We need to find a cell we can append to. If we don't find one we'll prepend the first cell
						if (current_rowspan > 1 && (current.data('row') != i || current.data('col') != startreference)) {
							current = null;
							for (j = startreference; j >= 0; --j) {
								if (cellmap[i + ',' + j].data('row') == i && cellmap[i+','+j].data('col') == j) {
									current = cellmap[i + ',' + j];
									break;
								}
							}
						}
					}
				}


				for (var j = start; j < start + count; ++j) {
					var newcell = self._createCell(i, j);
					cellmap[i + ',' + j] = newcell;
					newcells.push($(newcell));

					if (current == null) {
						referencerow.prepend(newcell)
					} else {
						current.after(newcell);
					}
					current = newcell;
				}
			}

			self.cols = nbcols+count;

			self._calculateTableWidth();
			//perform callbacks for newly added cells
			if (callbacks) {

				if ($.isFunction(saveProperties)) {
					saveProperties({
						'cols': nbcols+count,
						'rows': nbrows,
						'cellwidth': self.options.defaultCellWidth,
						'cellheight': self.options.defaultCellHeight,
						'table': self.serialize()
					});
				}

				if ($.isFunction(afterCellsAdded) && newcells.length > 0) {
					afterCellsAdded(newcells);
				}

				if ($.isFunction(afterCellsUpdated) && updatedcells.length > 0) {
					afterCellsUpdated(updatedcells);
				}

				self.refreshPositions();
			}

			if(self.options.debug) {
				self._debugCells();
			}

			if (self.options.fitToCell != null) {
				for (var i = 0; i < nbrows; ++i) {
					self.updateFitToCellForRow(i);
				}
			}
			//no merged ranges, succesfully added the range
			table.selectable('refresh');
			return newcells;


		},

		removeColumns: function(count, cell, executeCallbacks) {

			var self = this;
			var nbcols = self.cols;
			var nbrows = self.rows;
			var table = self.table;
			var body = self.tbody;
			var cellmap = self.cellmap;
			var saveProperties = self.options.saveProperties;
			var afterCellsRemoved = self.options.afterCellsRemoved;
			var afterCellsUpdated = self.options.afterCellsUpdated;
			var deleteCells = new Array();
			var updatedcells = new Array();

			var callbacks = executeCallbacks ? true:false;
			var rows = body.children('tr');

			var start = $(cell).data('col');

			table.css('width', 'auto');

			if (self._checkForMergedCells('current', 'col', cell)) {
				self._errorNotify("Columns can't be removed from merged cells");
				return deleteCells;
			}

			for (var i = nbrows - 1; i >= 0; --i) {
				for (var j = start; j < start + count; ++j) {
					var cell = cellmap[i + ',' + j];
					deleteCells.push(cell.clone(true));
					cell.remove();
				}
			}

			for (var j = start+count; j < nbcols; ++j) {
				for(var i=nbrows-1; i >= 0; --i) {
					var row = $(rows[i]).children('td');

					//update the after cells
					var current = cellmap[i+','+(start+count)];
					var updatecell = cellmap[i+','+j];

					if (i  == updatecell.data('row') && j == updatecell.data('col')) {
						var newcol = updatecell.data('col') - count;
						var rowspan = parseInt(updatecell.attr('rowspan'));
						var colspan = parseInt(updatecell.attr('colspan'));

						rowspan = isNaN(rowspan) ? 1 : rowspan;
						colspan = isNaN(colspan) ? 1 : colspan;

						updatecell.data('col', newcol);

						for(var k = i; k < i+rowspan; ++k){
							for(var l = newcol; l < newcol+colspan; ++l) {
								cellmap[k+','+l] = updatecell;
							}
						}

						updatedcells.push(updatecell)
					}
				}
			}


			self.cols = nbcols-count;
			self._calculateTableWidth();

			if (callbacks) {

				if ($.isFunction(saveProperties)) {
					saveProperties({
						'cols': nbcols - count,
						'rows': nbrows,
						'cellwidth': self.options.defaultCellWidth,
						'cellheight': self.options.defaultCellHeight,
						'table': self.serialize()
					});
				}

				if ($.isFunction(afterCellsRemoved)) {

					afterCellsRemoved(deleteCells);
				}

				if ($.isFunction(afterCellsUpdated) && updatedcells.length > 0) {
					afterCellsUpdated(updatedcells);
				}

				self.refreshPositions();
			}

			if(self.options.debug) {
				self._debugCells();
			}

			table.selectable('refresh');
			return deleteCells;

		},


		addRows: function(count, cell, position, executeCallbacks) {

			var self = this;
			var nbcols = self.cols;
			var nbrows = self.rows;
			var table = self.table;
			var body = self.tbody;
			var cellmap = self.cellmap;
			var callbacks = executeCallbacks ? true: executeCallbacks;

			var rownumber = 0;
			var rowspan = 1;

			var newcells = new Array();
			var updatedcells = new Array();

			var rows = body.children('tr');

			var currentrow = null;
			var start = 0;

			if (cell != null) {

				rownumber = $(cell).data('row');
				rowspan = $(cell).attr('rowspan');
				rowspan = isNaN(rowspan) ? 1 : rowspan;

				if (self._checkForMergedCells(position, 'row', cell)) {
					self._errorNotify("Rows can't be added to merged cells");
					return newcells;
				}


				//update all the after cell positions in preparation for adding in the new rows
				start = (position == 'after' ? rownumber + rowspan : rownumber);

				for (var i = nbrows - 1; i >= start; --i) {
					var cells = $(rows[i]).children('td');
					for (var j = 0; j < nbcols ; ++j) {
						currentcell = cellmap[i + ',' + j];


						if (i == currentcell.data('row') && j == currentcell.data('col')) {
							var newrow = currentcell.data('row') + count;
							currentcell.data('row', newrow);
							updatedcells.push(currentcell);


							var currentcell_rowspan = parseInt(currentcell.attr('rowspan'));
							var currentcell_colspan = parseInt(currentcell.attr('colspan'));
							currentcell_rowspan = isNaN(currentcell_rowspan) ? 1 : currentcell_rowspan;
							currentcell_colspan = isNaN(currentcell_colspan) ? 1 : currentcell_colspan;

							for (k = newrow; k < newrow + currentcell_rowspan; ++k) {
								for (l = j; l < j + currentcell_colspan; ++l) {
									cellmap[k + ',' + l] = currentcell;
								}
							}

						}
					}
				}

				var rowAfterStart = (position == 'after' ? rownumber + rowspan - 1 : rownumber - 1);


				if (rowAfterStart >= 0) {
					currentrow = $(rows[rowAfterStart]);
				}	else {
					currentrow = null;
				}

			}


			for (var i = start; i < start + count ; ++i) {

				var newrow = $('<tr></tr>');
				for (var j = 0; j < nbcols; ++j) {
					var newcell = this._createCell(i, j);
					newcells.push($(newcell));
					newrow.append(newcell);
				}

				if (currentrow == null) {
					body.prepend(newrow);
				} else {
					currentrow.after(newrow);
				}
				currentrow = newrow;
			}

			self.rows = nbrows+count;

			if (callbacks) {
				if ($.isFunction(self.options.saveProperties)) {

					self.options.saveProperties({
						'cols': nbcols,
						'rows': nbrows + count,
						'cellwidth': self.options.defaultCellWidth,
						'cellheight': self.options.defaultCellHeight,
						'table': self.serialize()
					});

				}

				if ($.isFunction(self.options.afterCellsAdded) && newcells.length > 0) {
					self.options.afterCellsAdded(newcells);
				}

				if ($.isFunction(self.options.afterCellsUpdated) && updatedcells.length > 0) {
					self.options.afterCellsUpdated(updatedcells);
				}

				self.refreshPositions();
			}

			if(self.options.debug) {
				self._debugCells();
			}

			table.selectable('refresh');
			return newcells;

		},

		removeRows: function(count, cell, executeCallbacks) {
			var self = this;
			var cellmap = self.cellmap;
			var nbcols = self.cols;
			var nbrows = self.rows;
			var table = self.table;
			var body = self.tbody;
			var deletedCells = new Array();
			var updatedcells = new Array();
			var callbacks = executeCallbacks ? true: executeCallbacks;
			var rows = body.children('tr');

			var start = cell.data('row');

			if(self._checkForMergedCells('current', 'row', cell)) {
				self._errorNotify("Rows can't be deleted from merged cells");
				return deletedCells;
			}

			for (var i = start; i < start + count; ++i) {

				var deleteCells = $(rows[i]).children('td');

				for(var k=0; k<=deleteCells.length; ++k) {
					deletedCells.push($(deleteCells[k]).clone(true));
				}

				$(rows[i]).remove();
			}

			//update after cell positions
			for(var i = start + count; i < nbrows; ++i) {
				var cells = $(rows[i]).children('td');
				for (var j = 0; j < nbcols; ++j) {
					currentcell = cellmap[i + ',' + j];
					if (i == currentcell.data('row') && j == currentcell.data('col')) {
						var newrow = currentcell.data('row') - count;
						currentcell.data('row', newrow);
						updatedcells.push(currentcell);

						var currentcell_rowspan = parseInt(currentcell.attr('rowspan'));
						var currentcell_colspan = parseInt(currentcell.attr('colspan'));
						currentcell_rowspan = isNaN(currentcell_rowspan) ? 1 : currentcell_rowspan;
						currentcell_colspan = isNaN(currentcell_colspan) ? 1 : currentcell_colspan;

						for (k = newrow; k < newrow + currentcell_rowspan; ++k) {
							for (l = currentcell.data('col'); l < currentcell.data('col') + currentcell_colspan; ++l) {
								cellmap[k + ',' + l] = currentcell;
							}
						}

					}
				}

			}

			//clear references in the bottom rows
			for(i = nbrows-count ; i < nbrows ; ++i ) {
				for(j = 0; j < nbcols; ++j) {
					cellmap[i+','+j] = undefined;
				}
			}


			self.rows = nbrows-count;

			if (callbacks) {
				if ($.isFunction(self.options.afterCellsRemoved)) {
					self.options.afterCellsRemoved(deletedCells);
				}

				if ($.isFunction(self.options.saveProperties)) {
					self.options.saveProperties({
						'cols': nbcols,
						'rows': nbrows - count,
						'cellwidth': self.options.defaultCellWidth,
						'cellheight': self.options.defaultCellHeight,
						'table': self.serialize()
					});
				}

				if ($.isFunction(self.options.afterCellsUpdated) && updatedcells.length > 0) {
					self.options.afterCellsUpdated(updatedcells);
				}

				self.refreshPositions();
			}



			if(self.options.debug) {
				self._debugCells();
			}

			table.selectable('refresh');
			return deletedCells;
		},


		mergeSelectedCells: function() {

			var self = this;
			var table = self.table;
			var body = self.tbody;
			var removedCells = [];

			var selected = body.find('.ui-selected');

			if(selected.length > 1) {

				var cellmap = self.cellmap;
				var firstcell = $(selected[0]);

				var rowspan = parseInt(firstcell.attr('rowspan'));
				var colspan = parseInt(firstcell.attr('colspan'));

				if(isNaN(rowspan)) {
					rowspan = 1;
				}

				if(isNaN(colspan)) {
					colspan = 1;
				}

				var top = firstcell.data('row');
				var bottom = top+rowspan-1;
				var left = firstcell.data('col');
				var right = left+colspan-1;

				//find the edges
				for(var i=1; i<selected.length; ++i) {
					var cell = $(selected[i]);
					var row = cell.data('row');
					var col = cell.data('col');
					var rowspan = parseInt(cell.attr('rowspan'));
					var colspan = parseInt(cell.attr('colspan'));

					if(isNaN(rowspan)) {
						rowspan = 1;
					}

					if(isNaN(colspan)) {
						colspan = 1;
					}

					if(row < top) {
						top = row;
					}

					if(col < left) {
						left = col;
					}

					if(row+rowspan-1 > bottom) {
						bottom = row+rowspan-1;
					}

					if(col+colspan-1 > right) {
						right = col+colspan-1;
					}
				}

				var newwidth = 0;
				var newheight = 0;
				var newrowspan = 0;
				var newcolspan = 0;

				for(var i=top; i <= bottom; ++i) {
					var cell = cellmap[i+','+left];

					if(cell.data('row')+','+cell.data('col') == i+','+left) {
						rowspan =  parseInt(cell.attr('rowspan'));

						if(isNaN(rowspan)) {
							rowspan = 1;
						}

						newrowspan += rowspan;
						newheight += cell.outerHeight();
					}
				}


				for(var j=left; j <= right; ++j ) {
					var cell = cellmap[top+','+j];
					//only need to do this for the first row
					if(cell.data('row')+','+cell.data('col') == top+','+j) {
						colspan =  parseInt(cell.attr('colspan'));

						if(isNaN(colspan)) {
							colspan = 1;
						}

						newcolspan += colspan;
						newwidth += cell.outerWidth();
					}
				}

				for(var i=top; i <= bottom; ++i) {
					for(var j=left; j <= right; ++j) {
						var temp = cellmap[i+','+j];
						if((i != top || j != left) && temp.data('row')+','+temp.data('col') == i+','+j) {
							removedCells.push(cellmap[i+','+j]);
							temp.remove();
							cellmap[i+','+j] = cellmap[top+','+left];
						} else {
							cellmap[i+','+j] = cellmap[top+','+left];
						}
					}
				}

				var cell = cellmap[top+','+left];
				cell.removeClass('ui-selected');
				cell.css('width', newwidth+'px');

				if(self.options.defaultCellHeight != null) {
					cell.css('height', newheight+'px');
				}

				cell.attr('rowspan',newrowspan);
				cell.attr('colspan',newcolspan);

				if($.isFunction(self.options.afterCellsRemoved)){
					self.options.afterCellsRemoved(removedCells);
				}

				if($.isFunction(self.options.afterCellsMerged)) {
					self.options.afterCellsMerged(cell);
				}

				if (self.options.fitToCell != null) {
					self.updateFitToCell(cell);
				}

				selected.removeClass('ui-selected');

				var saveProperties = self.options.saveProperties;

				if ($.isFunction(saveProperties)) {
					saveProperties({
						'cols': self.cols,
						'rows': self.rows,
						'cellwidth': self.options.defaultCellWidth,
						'cellheight': self.options.defaultCellHeight,
						'table': self.serialize()
					});
				}

				if(self.options.debug) {
					self._debugCells();
				}

			}

			table.selectable('refresh');
			self.refreshPositions();
		},

		breakApartSelected: function(selected) {

			var self = this;
			var table = self.table;
			var body = self.tbody;
			var selectedcells = body.find('.ui-selected');

			for(var i=0; i < selectedcells.length; ++i) {
				this.breakApartCell($(selectedcells[i]).data('row'), $(selectedcells[i]).data('col'), selected);
			}

			if(self.options.debug) {
				self._debugCells();
			}

			selectedcells.removeClass('ui-selected');
			var saveProperties = self.options.saveProperties;

			if ($.isFunction(saveProperties)) {
				saveProperties({
					'cols': self.cols,
					'rows': self.rows,
					'cellwidth': self.options.defaultCellWidth,
					'cellheight': self.options.defaultCellHeight,
					'table': self.serialize()
				});
			}

			table.selectable('refresh');
		},

		breakApartCell: function(row, col, selected) {
			var self = this;
			var cellmap = self.cellmap;
			var table = self.table;
			var body = table.children('tbody');
			var rows = body.children('tr');

			var cell = cellmap[row+','+col];
			var cellrow = cell.data('row');
			var cellcol = cell.data('col');

			var colspan = parseInt(cell.attr('colspan'));
			var rowspan = parseInt(cell.attr('rowspan'));
			var newcells = new Array();

			if(isNaN(colspan)) {
				colspan = 1;
			}

			if(isNaN(rowspan)) {
				rowspan = 1;
			}

			if(colspan > 1 || rowspan > 1) {

				var startrow = row;
				var startcol = col;

				var endrow = row + rowspan;
				var endcol = col + colspan;

				var currentrow;
				var currentcell;

				for(var i=startrow; i < endrow; ++i) {
					currentrow = $(rows[i]);
					if(i == startrow ) {
						currentcell = cell;
					} else {

						//find the first non/rowspaned cell or rowspan cell on this

						currentcell = null;
						for(var k=(col-1); k >= 0; --k) {
							var tempcell = cellmap[i+','+k];

							if(tempcell.data('row')+','+tempcell.data('col') == i+','+k) {
								//found a cell we can use as the start point
								currentcell = tempcell;
								break;
							}

						}

					}

					for(var j=startcol; j < endcol; ++j) {
						if(i != row || j != col) {
							var newCell = self._createCell(i,j);
							newcells.push(newCell);
							if(selected == true) {
								newCell.addClass('ui-selected');
							}

							if(currentcell == null) {
								//didn't find a cell to put the row after so append to the row
								currentrow.prepend(newCell);
							} else {
								currentcell.after(newCell);
							}

							currentcell = newCell;
						}
					}
				}

				cell.attr('colspan', 1);
				cell.attr('rowspan', 1);

				cell.css('width', self.options.defaultCellWidth+'px');

				if(self.options.defaultCellHeight != null) {
					cell.css('height', self.options.defaultCellHeight+'px');
				}

				if($.isFunction(self.options.afterCellsAdded)){
					self.options.afterCellsAdded(newcells);
				}

				if($.isFunction(self.options.afterCellsBroken)) {
					self.options.afterCellsBroken(cell);
				}

			}

			table.selectable('refresh');
			self.refreshPositions();

		},

		_createCell: function(row, col){
			var self = this;
			var defaultCellHeight = self.options.defaultCellHeight;
			var defaultCellWidth = self.options.defaultCellWidth;
			var defaultCellMinHeight = self.options.defaultCellMinHeight;
			var defaultCellPadding = self.options.defaultCellPadding;
			var newCellContent = self.options.newCellContent;
			var cellmap = self.cellmap;

			var cell = $('<td></td>');

			if(defaultCellHeight != null) {
				cell.css('height', defaultCellHeight+'px');
			}

			if(defaultCellWidth != null) {
				cell.css('width', defaultCellWidth+'px');
			}

			if(defaultCellMinHeight != null) {
			//cell.css('min-height', defaultCellMinHeight+'px');
			}

			if(defaultCellPadding != null) {
				cell.css('padding', defaultCellPadding+'px');
			}

			if(newCellContent != null) {

				if($.isFunction(newCellContent)) {
					newCellContent(cell);
				} else {
					cell.append(newCellContent);
				}
			}

			cell.data('row', row);
			cell.data('col', col);
			cellmap[row+','+col] = cell;
			return cell;
		},


		_calculateTableWidth: function(){

			var self = this;
			var tablewidth = 0;

			//set the table and container width to a high value for the calculation
			self.container.css('width', 9999+'px');
			self.table.css('width', 'auto');

			var rows = self.tbody.children('tr');
			for (var i = 0; i < rows.length; ++i) {
				var cells = $(rows[i]).children('td');
				if (cells.length > 0) {
					for (j = 0; j < cells.length; ++j) {
						var cellwidth = $(cells[j]).outerWidth();
						cellwidth = isNaN(cellwidth) ? self.options.defaultCellWidth : cellwidth;
						tablewidth += cellwidth;
					}
					break;
				}
			}

			self.table.css('width', tablewidth+'px');
			self.container.css('width', tablewidth+'px');
		},


		_errorNotify: function(message){
			var errorDialog = $('<div title="Error">'+message+'</div>');
			$('body').append(errorDialog);
			errorDialog.dialog({
				modal: true,
				buttons: {
					Ok: function() {
						$(this).dialog('close');
					}
				}
			});
		},

		_checkForMergedCells: function(position, direction, cell) {


			if (cell !== undefined) {
				var self = this;
				var cellmap = self.cellmap;
				var nbcols = self.cols;
				var nbrows = self.rows;

				var rownumber = cell.data('row');
				var columnnumber = cell.data('col');

				var refRowspan = parseInt(cell.attr('rowspan'));
				refRowspan = isNaN(refRowspan) ? 1 : refRowspan;

				var refColspan = parseInt(cell.attr('colspan'));
				refColspan = isNaN(refColspan) ? 1 : refColspan;

				if (direction == 'row' || direction == 'both') {
					if (position == 'before' || position == 'current') {
						for (var i = 0; i < nbcols; ++i) {
							if (cellmap[rownumber + ',' + i].data('row') != rownumber) {
								return true;
							}
						}
					}

					if (position == 'after' || position == 'current') {
						var adjustedRownumber = rownumber + refRowspan - 1;
						for (var i = 0; i < nbcols; ++i) {

							if (i < columnnumber || i > columnnumber + refColspan - 1) {
								var cell = cellmap[adjustedRownumber + ',' + i];
								var rowspan = parseInt(cell.attr('rowspan'));
								rowspan = isNaN(rowspan) ? 1 : rowspan;

								if (cell.data('row') + rowspan - 1 != adjustedRownumber) {
									return true;
								}
							}
						}
					}
				}

				if (direction == 'col' || direction == 'both') {


					if (position == 'before' || position == 'current') {
						for (var i = 0; i < nbrows; ++i) {
							if (cellmap[i + ',' + columnnumber].data('col') != columnnumber) {
								return true;
							}
						}
					}

					if (position == 'after' || position == 'current') {
						var adjustedColumnnumber = columnnumber + refColspan - 1;
						for (var i = 0; i < nbrows; ++i) {

							if (i < rownumber || i > rownumber + refRowspan - 1) {

								var current = cellmap[i + ',' + adjustedColumnnumber];
								var colspan = parseInt(current.attr('colspan'));
								colspan = isNaN(colspan) ? 1 : colspan;

								if (current.data('col') + colspan - 1 != adjustedColumnnumber) {
									return true;
								}
							}
						}
					}
				}

			}
			return false;
		},


		_debugCells: function(){

			var cellmap = self.cellmap;
			var rows = self.rows;
			var cols = self.cols;
			var table = self.table;

			for(var i=0; i<rows; ++i) {
				for(var j=0; j<cols; ++j) {
					if (cellmap[i + ',' + j] !== undefined) {

						if (i == cellmap[i + ',' + j].data('row') && j == cellmap[i + ',' + j].data('col')) {
							var index = cellmap[i + ',' + j].find('.index');
							if (index.length > 0) {
								$(index[0]).empty();
								$(index[0]).append(i + ',' + j + ':' + cellmap[i + ',' + j].data('row') + ',' + cellmap[i + ',' + j].data('col'));
							}
							else {
								cellmap[i + ',' + j].append('<div class="index">' + i + ',' + j + ':' + cellmap[i + ',' + j].data('row') + ',' + cellmap[i + ',' + j].data('col') + '</div>');
							}
						}
					} else {
						//alert(i+','+j);
					}
				}
			}

			table.selectable('refresh');

		},


		_findCell: function(x, y){

				var self = this;
				var cells = self.cells;

				var found = false;
				var selectedCell = null;

				for(var i=0; i<cells.length; ++i) {
					var cell = cells[i];

					if(cell.left <= x && cell.top <= y && cell.right >= x && cell.bottom >= y) {
						found = true;
						selectedCell = cell;
						break;
					}
				}

				if(found) {
					return selectedCell;
				}

				return null;
		},


		_setNewColumnWidth: function(cell, newWidth) {

			var self = this;
			var cellmap = self.cellmap;
			var nbrows = self.rows;
			var table = self.table;
			var container = self.container;
			var updated = {};

			var row = cell.data('row');
			var col = cell.data('col');

			var reference = cellmap[row+','+col];
			var currentwidth = reference.width();

			var diff = newWidth - currentwidth;

			for(var i=0; i<nbrows; ++i) {

				var tcell = cellmap[i+','+col];

				if(updated[tcell.data('row')+','+tcell.data('col')] !== true) {
					var colspan = parseInt(tcell.attr('colspan'));
					colspan = isNaN(colspan) ? 1 : colspan;

					if(colspan > 1) {
						var twidth = tcell.width();
						twidth = twidth + diff;
						tcell.css('width', twidth+"px");
					} else {
						tcell.css('width', newWidth+"px");
					}
					updated[tcell.data('row')+','+tcell.data('col')] = true;
				}

			}

			var tablewidth = table.width();
			table.css('width', (tablewidth+diff)+'px');
			container.css('width', (tablewidth+diff)+'px');

		},

		_setNewRowHeight: function(cell, newHeight) {

			var self = this;
			var cellmap = self.cellmap;
			var nbcols = self.cols;
			var updated = {};

			var row = cell.data('row');
			var col = cell.data('col');

			var reference = cellmap[row+','+col];
			var currentheight = reference.height();
			var diff = newHeight - currentheight;

			for(var j=0; j<nbcols; ++j) {

				var tcell = cellmap[row+','+j];

				if(updated[tcell.data('row')+','+tcell.data('col')] !== true) {
					var rowspan = parseInt(tcell.attr('rowspan'));
					rowspan = isNaN(rowspan) ? 1 : rowspan;

					if(rowspan > 1) {
						var theight = tcell.height();
						theight = theight + diff;
						tcell.css('height', theight+"px");
					} else {
						tcell.css('height', newHeight+"px");
					}
					updated[tcell.data('row')+','+tcell.data('col')] = true;
				}
			}


		},

		updateFitToCellForRow: function(row) {
			var self = this;
			var selector = self.options.fitToCell;
			var table = self.table;
			var numcols = self.options['cols'];
			var cellmap = self.options['cellmap'];
			var defaultWidth = self.options['defaultCellHeight'];

			for(var j=0; j<numcols; ++j) {
				var cell = cellmap[row+','+j];

				if (cell !== undefined) {
					if (cell.data('row') == row && cell.data('col') == j) {
						var rowspan = parseInt(cell.attr('rowspan'));
						var colspan = parseInt(cell.attr('colspan'));

						rowspan = isNaN(rowspan) ? 1 : rowspan;
						colspan = isNaN(colspan) ? 1 : colspan;

						cell.find(selector).css({
							//'min-height': (self.options.defaultCellHeight * rowspan) + 'px',
							'width': (self.options.defaultCellWidth * colspan) + 'px'
						});
					}
				}

			}

			for (var j = 0; j < numcols; ++j) {
				var cell = cellmap[row + ',' + j];

				if (cell !== undefined) {
					if (cell.data('row') == row && cell.data('col') == j) {
						var height = $(cell).height();
						var width = $(cell).width();

						if (width > 0) {
							//$(cell).find(selector).css('min-height', height + 'px');
							$(cell).find(selector).css('width', width + 'px');
						}
					}
				}
			}

			table.selectable('refresh');

		},


		updateFitToCell: function(cell) {

			var self = this;
			var selector = self.options.fitToCell;
			var table = self.table;


			if (selector != null) {
				var height = $(cell).height();
				var width =  $(cell).width();


				if (width > 0) {
					//$(cell).find(selector).css('min-height', height + 'px');
					$(cell).find(selector).css('width', width + 'px');
				}

				$(this).css('height', 'auto');

			}
			table.selectable('refresh');
		},

		//converts the table to a string that can be saved on the server
		serialize: function() {
			var self = this;
			var cellmap = self.cellmap;
			var rows = self.rows;
			var cols = self.cols;
			var defaultCellHeight = self.options.defaultCellHeight;
			var table = self.table;

			//reset margins for save
			self.table.css({'margin-right': '0', 'margin-bottom': '0'});
			defaultCellHeight = defaultCellHeight === undefined || defaultCellHeight === null ? '' : defaultCellHeight;

			var defaultCellWidth  = self.options.defaultCellWidth;
			defaultCellWidth = defaultCellWidth === undefined || defaultCellWidth === null ? '' : defaultCellWidth;

			var defaultCellStyles = self.options.defaultCellStyles;
			defaultCellStyles = defaultCellStyles === undefined || defaultCellStyles === null ? '' : defaultCellStyles;

			var tableStyles = table.attr('style');
			var tableStr = rows+','+cols+','+defaultCellWidth+','+defaultCellHeight+','+defaultCellStyles+','+tableStyles+'<>';

			for(var i=0; i<rows; ++i) {
				for (var j = 0; j < cols; ++j) {
					var cell = cellmap[i+','+j];
					if (cell !== undefined) {
						var row = cell.data('row');
						var col = cell.data('col');
						var rowspan = parseInt(cell.attr('rowspan'));
						rowspan = isNaN(rowspan) ? 1 : rowspan;
						var colspan = parseInt(cell.attr('colspan'));
						colspan = isNaN(colspan) ? 1 : colspan;
						// MRW: Remove min-height before saving to fix IE: bug where it uses the min-height...
						cell.css('min-height', '');
						var style = cell.attr('style');

						if (row == i && col == j) {
							tableStr += row + ',' + col + ',' + rowspan + ',' + colspan + ',' + style;

							if (i != rows - 1 || j != cols - 1) {
								tableStr += '|'
							}
						}
					} else {
						alert(i+','+j);
					}
				}
			}
			return tableStr;

			//re-add the table margins to account for the right click menu
			self.table.css({'margin-bottom': '200px'});

		},

		refresh: function() {
			var self = this;
			if(!self.disabled)
				this.table.selectable('refresh');
			this.refreshPositions();
		},

		getCell: function(x,y) {
			return this.options.cellmap[x+','+y];
		},


		refreshPositions: function(){

			var self = this;
			self.cells = new Array();

			for(var i=0; i<self.rows; ++i) {
				for(var j=0; j<self.cols; ++j) {
					var cell = self.cellmap[i+','+j];
					if (cell === undefined) {
						cell = self._createCell(i,j);
						cell.data('row', i);
						cell.data('col', j);
						self.cellmap[i+','+j];
					}

					if (i == cell.data('row') && j == cell.data('col')) {
						var p = cell.offset();
						cell.left = p.left;
						cell.top = p.top;
						cell.bottom = cell.top + cell.outerHeight();
						cell.right = cell.left + cell.outerWidth();
						self.cells.push(cell);
					}

				}
			}
		},

		setupTableDraggables: function(elements) {
			var self = this, o = this.options
			if (o.enabled) {
				elements.find(o.acceptHover).hover(function(){
					$(this).find(o.acceptHandle).show();
					$(this).find('.ocms-actions').show();
				}, function(){
					$(this).find(o.acceptHandle).hide();
					$(this).find('.ocms-actions').hide();
				});

				elements.draggable({
					helper: 'clone',
					handle: o.acceptHandle,
					revert: 'invalid',
					appendTo: 'body',
					stack: o.accept,
					zIndex: 99,

					start: function(event, ui){
						ui.helper.css('width', '300px');
						ui.helper.css('height', 'auto');
						ui.helper.css('overflow', 'hidden');
						$(this).hide();
					},

					stop: function(event, ui){
						if ($(this).data('received') !== true) {
							$(this).show();
						}
						else {
							$(this).data('received', false);
						}
					}
				});
			}
		},

		clearCells: function(){

			//get a list of all the elements inserted into the table
			var self = this, o = self.options;
			var elements = self.table.find(o.accept);
			elements.remove();
			if($.isFunction(o.afterCellsCleared)) {
				o.afterCellsCleared(elements);
			}

		},

		options: {
			version: "1.0",
			newCellContent: null,
			defaultRows: 6,
			defaultColumns: 2,
			afterCellsAdded: null,
			afterCellsRemoved: null,
			afterCellsMerged: null,
			afterCellsBroken: null,
			afterCellsUpdated: null,
			afterCellsCleared: null,
			defaultCellHeight: 30,
			defaultCellMinHeight: 30,
			defaultCellWidth: 250,
			defaultCellPadding: 5,
			defaultTableWidth: 250,
			received: null,
    		saveProperties: null,
			fitToCell: null,
			disabled: false,
			debug: false,
			accept: '.ui-draggable',
			acceptHandle: '.tableitem-handle',
			acceptHover: '.tableitem-hover',
			enabled: true
		}


	});

})(jQuery);