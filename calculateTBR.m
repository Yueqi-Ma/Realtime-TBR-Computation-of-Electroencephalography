function tbrValues = calculateTBR(interfaceAddress, interfacePort, bytesToRead, bufferSize, thetaFreqRange, betaFreqRange)
    % 全局变量
    n = 15; % 一次读入的点数，1个点33个字节

    global x;
    global powerSpectrum;

    for i = 1:9
        eval(['global',' ch',num2str(i),';'])
        eval(['global',' sp',num2str(i),';'])
        eval(['ch',num2str(i) '= 0;']);
    end

    global step;

    step = n; % 坐标轴补偿，应该和读入字节数相同

    t = 0;
    m = 0;
    x = 0;
    powerSpectrum = [];

    % TCPIP连接设置
    interfaceObject = tcpip(interfaceAddress, interfacePort, 'NetworkRole', 'client');
    interfaceObject.InputBuffersize = 33 * n;
    interfaceObject.RemoteHost = interfaceAddress;
    bytesToRead = 33 * n;

    % 设置窗口
    figureHandle = figure('NumberTitle', 'off',...
        'Name', 'TBR动态图',...
        'Color', [1 1 1],...
        'position', [1 1 1536 864/3],...
        'CloseRequestFcn', {@localCloseFigure, interfaceObject});

    % 设置axis
    axesHandle = axes('Parent', figureHandle,...
        'YGrid', 'on',...
        'YColor', [1 1 1],...
        'XGrid', 'on',...
        'XColor', [0 0 0],...
        'Color', [0 0 0]);
    xlabel(axesHandle, '时间');
    ylabel(axesHandle, 'TBR');

    % 初始化绘图
    plotHandle = plot(0, '-', 'LineWidth', 1, 'color', [0 0 1]);
    grid minor

    % 初始化PSD计算相关变量
    bufferCount = 0; %缓存计数器
    thetaPSD = []; % 存储θ波频率段的PSD
    betaPSD = []; % 存储β波频率段的PSD
    tbr = []; % 存储TBR值

    fopen(interfaceObject);

    pause(2);
    fprintf(interfaceObject, 'b');

    while isvalid(interfaceObject)
        % 检查是否有足够的数据读取
        if interfaceObject.BytesAvailable >= bytesToRead
            data_recv = fread(interfaceObject, bytesToRead);
            data_recv1 = reshape(data_recv, [33, n])';

            % 将接收到的数据转换为信号向量
            data = double(data_recv1(:, 2:33));

            % 更新全局变量x
            x = [x; data(:)];

            % 更新缓存计数器
            bufferCount = bufferCount + size(data, 1);

            % 如果缓存已满，则计算功率谱密度并绘制
            if bufferCount >= bufferSize
                % 计算当前缓存中数据的功率谱密度（PSD）
                [pxx, f] = pwelch(x(end-bufferCount+1:end), [], [], [], 1000);

                % 计算θ波频率段的平均PSD
                thetaIdx = find(f >= thetaFreqRange(1) & f <= thetaFreqRange(2));
                thetaAvgPSD = mean(pxx(thetaIdx));
                thetaPSD = [thetaPSD; thetaAvgPSD];

                % 计算β波频率段的平均PSD
                betaIdx = find(f >= betaFreqRange(1) & f <= betaFreqRange(2));
                betaAvgPSD = mean(pxx(betaIdx));
                betaPSD = [betaPSD; betaAvgPSD];

                % 计算TBR值
                tbrValue = thetaAvgPSD / betaAvgPSD;
                tbr = [tbr; tbrValue];

                % 清空缓存计数器
                bufferCount = 0;

                % 绘制动态图
                t = t + 1;
                set(plotHandle, 'XData', 1:t, 'YData', tbr);
                xlim(axesHandle, [max(0, t-100), t+50]);
                drawnow;
            end
        end
    end

    fclose(interfaceObject);
    delete(interfaceObject);

    tbrValues = tbr;
end

function localCloseFigure(~, ~, interfaceObject)
    fclose(interfaceObject);
    delete(interfaceObject);
    closereq;
end



%%
%以上代码将原始程序封装成了名为calculateTBR的函数，该函数接受输入参数：

%interfaceAddress：TCP/IP接口地址
%interfacePort：TCP/IP接口端口
%bytesToRead：读取的字节数
%bufferSize：缓存大小
%thetaFreqRange：θ波频率范围
%betaFreqRange：β波频率范围

%函数的输出参数为TBR值的时间序列tbrValues。
