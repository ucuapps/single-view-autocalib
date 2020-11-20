%
%  Copyright (c) 2018 James Pritts, Denys Rozumnyi, CTU in Prague
%  Licensed under the MIT License (see LICENSE for details)
%
%  Written by James Pritts and Denys Rozumnyi
%
classdef Img < handle
    properties
        real;
        data;
        height; 
        width;
        area;
        intensity;
        
        cid;
        url;
    end
    
    methods(Static)
        function filecontent = get_native_img(url)
            [fpath fname fext] = fileparts(url);
            switch (lower(fext))
              case {'.jpg', '.png', '.gif', '.pgm', ''}
              otherwise
                error('Unsuporrted extension.');
            end

            try
                img = imread(url);
            catch
                error('Not an image (according to matlab).');
            end

            filecontent = Img.fileread(url, inf, '*uint8');
        end
        
        function res = fileread(fname, count, precision)
            narginchk(2,3);
            fid = fopen(fname, 'r');
            if (fid < 0)
                error('File ''%s'' cannot be read.', fname);
            end
            
            if nargin == 2
                res = fread(fid, count);
            else
                res = fread(fid, count, precision);
            end
            
            fclose(fid);        
        end
    end
    
    methods(Access=public)
        function this = Img(varargin)
            cfg = struct('data',[],'url',[],'cid',[]);
            cfg = cmp_argparse(cfg,varargin{:});
            this.data = cfg.data;
            this.cid = cfg.cid;
            
            if ~isempty(cfg.url)
                this.url = fullfile(cfg.url);
            end

            if isempty(this.data) && ~isempty(this.url)
                this.data = imread(this.url);
                filecontents = Img.get_native_img(this.url);
                this.cid = KEY.hash(filecontents,'MD5');
            end

            this.calc_size();

            if (ndims(this.data) == 3)
                this.intensity = rgb2gray(this.data);
            elseif (ndims(this.data) == 1)
                this.intensity = data;
            end
            
            %   this.real = im2double(this.data);
        end

        function [] = calc_size(this)
            this.height = size(this.data,1);
            this.width = size(this.data,2);
            this.area = this.width*this.height;
        end
        
       
        function timg = transform(this,f,varargin)
            data = f(this.data,varargin);
            cid = KEY.hash(this.data,'MD5');
            timg = Img('data',data,'cid',cid);
        end 

    end
end
