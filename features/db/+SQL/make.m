%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
function [] = make_sqldb()
sql = SQL.SqlDb;
sql.open();
sql.clear();
sql.create();