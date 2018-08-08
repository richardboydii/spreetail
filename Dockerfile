FROM microsoft/dotnet:2.0-sdk AS build
WORKDIR /app

# copy csproj and restore as distinct layers
COPY *.sln .
COPY HelloWorld/*.csproj ./HelloWorld/
RUN dotnet restore

# copy everything else and build app
COPY HelloWorld/. ./HelloWorld/
WORKDIR /app/HelloWorld
RUN dotnet publish -c Release -o out


FROM microsoft/dotnet:2.0-runtime AS runtime
WORKDIR /app
COPY --from=build /app/HelloWorld/out ./
ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000
ENTRYPOINT ["dotnet", "HelloWorld.dll"]