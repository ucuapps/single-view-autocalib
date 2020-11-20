function img = get_image(img_path, max_side)
    if nargin < 2
        max_side = 3000;
    end

    img = Img('url', img_path);
    max_side_factor = max_side / max(img.width, img.height);
    if max_side_factor < 1
        img_data = imresize(imread(img_path), max_side_factor);
        imwrite(img_data, img_path);
        img = Img('url', img_path);
    end
end