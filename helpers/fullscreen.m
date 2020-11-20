function [] = fullscreen()
    set(gcf,'menubar','none');
    set(gcf,'NumberTitle','off');
    set(gcf,'units','normalized','outerposition',[0 0 1 1]);
    set(gca,'Unit','normalized','Position',[0 0 1 1]);
end