# 1
FROM swift:5.5
# 2
WORKDIR /package
# 3
COPY . ./
# 4
CMD ["swift", "build"]